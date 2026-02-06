# How I Approached Testing

## Introduction

As I developed my portfolio blogging app, one thing quickly became clear: **testing is essential**. Not only does it ensure the app works correctly, but it also demonstrates a disciplined, professional approach to development — something recruiters really notice.

In this post, I want to share **how I implemented tests**, what I learned, and how I plan to extend testing to cover the entire application.

---

## Testing the `/create-user` Endpoint

The first major piece I tackled was **user creation**. This endpoint has several responsibilities:

- Validating mandatory fields like `username` and `full_name`.
- Ensuring passwords and emails meet security and format requirements.
- Preventing duplicate users in the database.
- Handling optional fields like `bio`.

To verify all of this, I wrote **automated tests using FastAPI’s `TestClient` and pytest**.

### Example Test

```python
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_user_success():
    payload = {
        "username": "peter_barasa",
        "full_name": "Peter Barasa",
        "email": "barasapeter52@gmail.com",
        "password": "StrongPass1"
    }
    response = client.post("/api/v1/create-user", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "User created successfully"
```

### What I Learned

* **Test isolation**: Tests should run without depending on production data. Using separate or in-memory databases ensures consistency.
* **Edge cases matter**: Testing just the "happy path" isn’t enough. Missing fields, invalid passwords, and duplicate users all require coverage.
* **Error handling is critical**: Writing tests forces me to think about the ways the endpoint can fail and ensures meaningful error messages are returned.
* **Confidence in refactoring**: With tests in place, I can safely make changes knowing functionality is preserved.

---

## Expanding Test Coverage

The knowledge I gained while testing user creation will guide **future tests for the app**. Some areas I plan to cover:

1. **Posts and categories**

   * Create, update, and delete blog posts.
   * Validate slugs, titles, and content lengths.
   * Ensure proper category assignment.

2. **Comments and moderation**

   * Test comment submission, approval, and rejection.
   * Handle nested comments and replies.
   * Verify email notifications or alerts if implemented.

3. **Authentication and authorization**

   * Test login, logout, and password resets.
   * Ensure protected routes are inaccessible without proper authentication.

4. **Optional fields and edge cases**

   * Test optional fields like `bio` or `excerpt` for boundary values.
   * Check app behavior when unexpected data is submitted.

5. **Error handling and internal failures**

   * Simulate database errors or invalid JSON payloads.
   * Confirm the app responds gracefully and logs issues properly.

---

## My Approach Going Forward

I now have a **structured approach to testing**:

* **Write tests as I develop**: I don’t leave testing for the end.
* **Cover success, failure, and edge cases**: Ensures robust and predictable behavior.
* **Use mocks and test DBs**: Avoid affecting real data or production logs.
* **Log insights during testing**: Helps track unexpected behavior and informs future improvements.

This approach not only **improves code quality** but also **demonstrates professionalism**, something recruiters notice in portfolio projects.

---

## Conclusion

Testing has shifted from being an afterthought to a **core part of my development workflow**. By focusing on the `/create-user` endpoint first, I gained valuable insights into designing comprehensive test coverage.

Going forward, I plan to apply these principles across all app features, gradually building **a fully-tested, robust blogging platform**.

This project now reflects both **technical skills** and **a disciplined approach to software development**, making it my favorite blog.
