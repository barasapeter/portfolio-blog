const viewMode = document.getElementById('viewMode');
const editMode = document.getElementById('editMode');
const editBtn = document.getElementById('editBtn');
const cancelBtn = document.getElementById('cancelBtn');
const pageTitle = document.getElementById('pageTitle');
const profileForm = document.getElementById('profileForm');

const avatarInput = document.getElementById('avatarInput');
const avatarPreview = document.getElementById('avatarPreview');
const bioInput = document.getElementById('bioInput');
const charCount = document.getElementById('charCount');

editBtn.addEventListener('click', () => {
    viewMode.classList.add('hidden');
    editMode.classList.remove('hidden');
    editBtn.classList.add('hidden');
    pageTitle.textContent = 'Edit Profile';
});

cancelBtn.addEventListener('click', () => {
    editMode.classList.add('hidden');
    viewMode.classList.remove('hidden');
    editBtn.classList.remove('hidden');
    pageTitle.textContent = 'Profile';
});

avatarInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
        if (file.size > 2 * 1024 * 1024) {
            alert('File must be less than 2MB');
            e.target.value = '';
            return;
        }
        const reader = new FileReader();
        reader.onload = (e) => {
            avatarPreview.src = e.target.result;
        };
        reader.readAsDataURL(file);
    }
});

bioInput.addEventListener('input', () => {
    charCount.textContent = bioInput.value.length;
});

profileForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const formData = new FormData();
    formData.append('full_name', document.getElementById('fullNameInput').value);
    formData.append('username', document.getElementById('usernameInput').value);
    formData.append('email', document.getElementById('emailInput').value);
    formData.append('bio', bioInput.value);

    if (avatarInput.files[0]) {
        formData.append('avatar', avatarInput.files[0]);
    }

    try {
        const response = await fetch('/account/update', {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            window.location.reload();
        } else {
            alert('Failed to update profile');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('An error occurred');
    }
});