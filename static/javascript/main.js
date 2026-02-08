function showToast(message, type = 'success', duration = 3000) {
    const toast = document.getElementById('auth-toast');
    toast.textContent = message;

    toast.classList.remove('bg-green-600', 'bg-red-500');
    toast.classList.add(type === 'success' ? 'bg-green-600' : 'bg-red-500');

    toast.classList.remove('-translate-y-20', 'opacity-0', 'pointer-events-none');
    toast.classList.add('translate-y-4', 'opacity-100');

    setTimeout(() => {
        toast.classList.remove('translate-y-4', 'opacity-100');
        toast.classList.add('-translate-y-20', 'opacity-0', 'pointer-events-none');
    }, duration);
}

window.addEventListener('DOMContentLoaded', () => {
    const authStatus = document.getElementById('auth-status').dataset.authenticated;
    if (authStatus === 'true') {
        showToast("You are logged in!", "success", 4000);
    } else {
        showToast("You are not logged in", "error", 4000);
    }
});