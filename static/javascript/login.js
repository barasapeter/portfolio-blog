document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("loginForm");
    const button = document.getElementById("loginBtn");
    const errorBanner = document.getElementById("errorBanner");

    if (!form || !button || !errorBanner) {
        console.error("Login form elements not found");
        return;
    }

    function setLoading(isLoading) {
        button.disabled = isLoading;
        button.textContent = isLoading ? "Signing in…" : "Next";
    }

    function showError(message) {
        errorBanner.textContent = message;
        errorBanner.classList.remove("hidden");
    }

    function clearError() {
        errorBanner.classList.add("hidden");
        errorBanner.textContent = "";
    }

    form.addEventListener("submit", async (e) => {
        e.preventDefault();
        clearError();

        const username = document.getElementById("username").value.trim();
        const password = document.getElementById("password").value;

        if (!username || !password) {
            showError("Please enter both username/email and password.");
            return;
        }

        setLoading(true);

        try {
            const res = await fetch("/api/v1/login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                credentials: "include",
                body: JSON.stringify({
                    username,
                    password,
                }),
            });

            const data = await res.json();

            if (!res.ok) {
                showError(data.detail || "Invalid credentials.");
                setLoading(false);
                return;
            }

            // success
            window.location.href = "/";
        } catch (err) {
            console.error(err);
            showError("Network error. Please try again.");
            setLoading(false);
        }
    });
});