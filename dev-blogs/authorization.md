# Authorization in Practice

## From Theory to Implementation

Once I built a complete authentication system for my blog app, as I described in my last post about authentication, I then had to solve the next problem - authorization.

Authentication is asking the user, "Who are you?" and getting a response; however, authorization is asking, "What can this user do?"

When I first thought of the authentication portion of the blog app, it seemed fairly easy. The complexity of how to handle authorization has been extremely difficult.

Authorization is where theory and practicality converge. How do we handle users with different levels of authority, their ownership of the resources, and the never-ending question of where to put authorization logic?

This article discusses how I have learned about authorization, the different approaches I considered, and the limits of what I could accomplish with this blog application.

---

## The Authorization Problem Space

In my blogging app, I needed to enforce several rules:

- **Anonymous users** can read published posts
- **Authenticated users** can create posts and comments
- **Post authors** can edit or delete their own posts
- **Comment authors** can delete their own comments
- **Future consideration**: Admin roles for moderation

The challenge wasn't just *implementing* these rules — it was deciding **where** and **how** to implement them cleanly.

---

## Learning Authorization: Key Concepts

Coming from authentication, I had to internalize several new concepts:

### 1. Authentication ≠ Authorization
- Authentication: "You are user #42"
- Authorization: "User #42 can delete post #100"

They're separate concerns that often get conflated.

### 2. Resource-Based vs Role-Based Access Control

**RBAC (Role-Based Access Control)**:
- Users have roles (admin, editor, viewer)
- Roles have permissions
- Simple to reason about, scales well for large teams

**Resource-Based (Ownership) Authorization**:
- "You can edit this because you created it"
- More granular, fits user-generated content naturally
- Common in social platforms and content apps

For a blogging platform, I needed **both**: ownership checks for posts/comments, with room for future role-based admin features.

### 3. Where Does Authorization Logic Live?

This was the hardest question. Options include:

- **In route handlers** (simple but repetitive)
- **As middleware** (DRY but inflexible)
- **In dependencies** (FastAPI-native, composable)
- **In service/business layer** (domain-driven)
- **In database layer** (via queries or RLS)

Each approach has tradeoffs between clarity, reusability, and testability.

---

## Authorization Choices I Evaluated

### Option 1: Manual Checks in Every Route

```python
@router.delete("/posts/{post_id}")
def delete_post(post_id: int, user_id: int = Depends(get_current_user)):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(404)
    if post.author_id != user_id:
        raise HTTPException(403, "Not authorized")
    db.delete(post)
    db.commit()
```

**Pros**: Explicit, easy to understand
**Cons**: Repetitive, easy to forget, mixes concerns

---

### Option 2: Decorator-Based Permissions

```python
@require_permission("delete:post")
@router.delete("/posts/{post_id}")
def delete_post(...):
    ...
```

**Pros**: Declarative, DRY
**Cons**: Less flexible for resource ownership, magic behavior

---

### Option 3: FastAPI Dependencies (Chosen)

```python
@router.delete("/posts/{post_id}")
def delete_post(
    post: Post = Depends(get_post_or_404),
    user_id: int = Depends(require_post_owner)
):
    # Authorization already handled by dependencies
    db.delete(post)
    db.commit()
```

**Pros**: Composable, testable, FastAPI-native, self-documenting
**Cons**: Requires understanding dependency injection

This aligned perfectly with my existing authentication pattern.

---

## The Implementation: Authorization Dependencies

I built a set of reusable authorization dependencies that compose naturally:

### 1. Resource Fetching Dependencies

```python
def get_post_or_404(
    post_id: int,
    db: Session = Depends(get_db)
) -> Post:
    """Fetch post or raise 404"""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return post
```

### 2. Ownership Verification Dependencies

```python
def require_post_owner(
    post: Post = Depends(get_post_or_404),
    user_id: int = Depends(get_current_user)
) -> Post:
    """Ensure current user owns the post"""
    if post.author_id != user_id:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to modify this post"
        )
    return post
```

### 3. Optional Ownership (for UI hints)

```python
def get_optional_post_owner(
    post: Post = Depends(get_post_or_404),
    user_id: int | None = Depends(get_optional_user)
) -> tuple[Post, bool]:
    """Return post and whether current user owns it"""
    is_owner = user_id is not None and post.author_id == user_id
    return post, is_owner
```

This last one was crucial for server-rendered templates — I could show/hide edit buttons based on ownership without duplicating logic.

---

## Real-World Usage Example

Here's how these dependencies compose in actual routes:

```python
@router.get("/posts/{post_id}")
def view_post(
    request: Request,
    data: tuple[Post, bool] = Depends(get_optional_post_owner)
):
    post, is_owner = data
    return templates.TemplateResponse(
        "post.html",
        {
            "request": request,
            "post": post,
            "show_edit_button": is_owner
        }
    )

@router.put("/posts/{post_id}")
def update_post(
    request: Request,
    post: Post = Depends(require_post_owner),
    db: Session = Depends(get_db)
):
    # User authorization already verified
    # Just handle the update logic
    form = await request.form()
    post.title = form["title"]
    post.content = form["content"]
    db.commit()
    return RedirectResponse(f"/posts/{post.id}")
```

Notice how authorization concerns are **declared in the signature**, not buried in route logic.

---

## Why This Approach Works

### 1. Single Responsibility
- Routes handle business logic
- Dependencies handle authorization
- Clear separation of concerns

### 2. DRY Without Magic
- Reusable authorization logic
- Explicit in route signatures
- No hidden decorators or middleware

### 3. Testability
- Dependencies can be overridden in tests
- Easy to mock authorization scenarios
- No framework gymnastics required

### 4. Self-Documenting
Looking at a route signature immediately reveals:
- What resources are required
- What permissions are checked
- What the route actually does

---

## Testing Authorization

I focused on three types of tests:

### 1. Unit Tests for Dependencies
```python
def test_require_post_owner_blocks_non_owner():
    # Mock post owned by user 1
    # Request from user 2
    # Should raise 403
```

### 2. Integration Tests for Routes
```python
def test_delete_post_requires_ownership():
    # Create post as user A
    # Attempt delete as user B
    # Verify 403 response
```

### 3. Template Authorization Tests
```python
def test_edit_button_only_shown_to_owner():
    # Render post page as owner → button present
    # Render as guest → button absent
```

The dependency pattern made these tests **significantly easier** than manual authorization checks scattered across routes.

---

## Design Decisions and Tradeoffs

### Why Not Database-Level Row Security?
PostgreSQL's RLS (Row-Level Security) is powerful, but:
- Adds complexity to database layer
- Makes debugging harder
- Doesn't play well with ORMs like SQLAlchemy
- Authorization logic becomes implicit

For this project, **explicit application-level checks** felt more maintainable.

### Why Not a Separate Authorization Service?
For a monolithic blogging app, microservices-style authorization (like Ory Keto or Open Policy Agent) would be overkill. But the dependency pattern leaves that door open.

### Why Return Tuples from Dependencies?
```python
post, is_owner = Depends(get_optional_post_owner)
```

This felt cleaner than creating wrapper objects. Python's tuple unpacking keeps it readable.

---

## Patterns That Emerged

As I built more features, several patterns crystallized:

### Pattern 1: Optional vs Required Authorization
```python
get_optional_user  # Returns None if not authenticated
get_current_user   # Raises 401 if not authenticated

get_optional_post_owner  # Returns (post, False) if not owner
require_post_owner       # Raises 403 if not owner
```

Naming convention makes intent clear.

### Pattern 2: Chained Dependencies
```python
require_post_owner(
    post = Depends(get_post_or_404),  # First fetch
    user_id = Depends(get_current_user)  # Then authorize
)
```

FastAPI resolves these in order automatically.

### Pattern 3: Template-Friendly Authorization
```python
{
    "show_edit_button": is_owner,
    "show_delete_button": is_owner,
    "show_admin_tools": is_admin
}
```

Server-rendered templates need boolean flags, not exceptions.

---

## What I Learned

1. **Authorization is about domain modeling**, not just security
2. **Where you put logic matters** as much as what the logic does
3. **Dependencies scale better** than decorators for complex cases
4. **Explicit is better than implicit** (Python's Zen applies here)
5. **Testing authorization in isolation** catches bugs early

Most importantly: **authorization should be visible in code structure**, not hidden behind abstraction layers.

---

## Future Improvements

This system is extensible but still simple. Planned enhancements:

- **Role-based permissions** for admin/moderator features
- **Permission caching** to reduce database queries
- **Audit logging** for authorization failures
- **More granular permissions** (edit vs delete)
- **Policy-as-code** using something like Oso or Casbin

---

## Closing Thoughts

Authorization initially felt like "just add some `if` statements," but treating it as a **first-class architectural concern** made the entire codebase cleaner.

The FastAPI dependency pattern turned out to be perfect for this:
- Composable
- Testable  
- Self-documenting
- Framework-aligned

Combined with my stateless JWT authentication, I now have a security model that:
- Works for server-rendered apps
- Could extend to APIs
- Doesn't require sessions or external services
- Remains readable six months later

---

## Key Takeaway

> Authorization isn't a feature you bolt on — it's a design problem that shapes your architecture. Solve it intentionally, and the rest of your code gets simpler.

If you're building a similar app, my advice:
1. Separate authentication from authorization **from day one**
2. Use your framework's native patterns (FastAPI dependencies, Django permissions, etc.)
3. Make authorization **visible** in your code
4. Test it like you'd test any other critical system

Next up: I'll be tackling **profile management and user permissions** — stay tuned for the next post in this series.