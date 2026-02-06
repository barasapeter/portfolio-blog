# How I Approached Testing

## Introduction

While creating my blog application, it became apparent to me that **testing is a must do** for BOTH the functionality of your app and as evidence of a well organized approach to developing a quality product.

This article will explain how I performed testing, what I learned from performing these tests, and my plans to expand testing across the full application.

---

## Testing the `/create-user` Endpoint

The initial element I worked on was **creating users**. This endpoint served multiple purposes such as:

- Validating required fields such as user name and full name.
- Ensuring that passwords meet the minimum security requirements and that email addresses conform to accepted formats.
- Preventing multiple users from being created in the database.
- Allowing users to provide optional information such as a brief biography.

I also created **automated tests with FastAPI's TestClient and pytest** to verify that everything worked correctly.

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

* **Isolate Tests**: Running tests completely indpendent of all production data. Use a separate database or an in-memory database to provide consistent results across all tests.
* **Edge Case Tests**: Tests should include edge cases whenever achievable. Missing fields, invalid passwords and users attempts at duplicates are all things to test for.
* **Importance of Error Handling**: Writing tests helps me think through the many ways an endpoint can fail and determine the appropriate message to return on failure.
* **Refactoring Confidence**: I can make confident changes because I have already tested the initial functionality before performing any changes.

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

This approach not only **improves code quality** but also **demonstrates professionalism**.

---

## Conclusion

Testing has gone from an afterthought to a **core component of my development workflow**. This has allowed me to have a clearer understanding of comprehensive testing coverage when designing my applications through focusing on the `/create-user` endpoint first.

As I continue through development, I want to apply this knowledge throughout all features of the application for the purpose of creating **an entirely tested and strong blogging platform**.

As a result, this project contains both **technical abilities** and **a structured development process**, making it my favourite blog.
