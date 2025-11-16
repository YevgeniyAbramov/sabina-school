// API Base URL
const API_URL = "/api/v1";

// Проверяем, может пользователь уже залогинен
document.addEventListener("DOMContentLoaded", () => {
  const token = localStorage.getItem("auth_token");
  if (token) {
    // Если токен есть - редирект на главную
    window.location.href = "/";
  }
});

// Показать уведомление
function showNotification(message, type = "success") {
  const notification = document.createElement("div");
  notification.className = `alert alert-${type} alert-dismissible fade show alert-custom`;
  notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
  document.getElementById("notifications").appendChild(notification);

  setTimeout(() => {
    notification.remove();
  }, 5000);
}

// Обработка формы входа
document.getElementById("loginForm").addEventListener("submit", async (e) => {
  e.preventDefault();

  const username = document.getElementById("username").value.trim();
  const password = document.getElementById("password").value;

  if (!username || !password) {
    showNotification("Заполните все поля", "warning");
    return;
  }

  try {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        username: username,
        password: password,
      }),
    });

    const data = await response.json();

    if (data.status && data.token) {
      // Сохраняем токен в localStorage
      localStorage.setItem("auth_token", data.token);

      // Сохраняем информацию о преподавателе (опционально)
      if (data.teacher) {
        localStorage.setItem("teacher_name", data.teacher.first_name);
      }

      showNotification("Вход выполнен успешно!", "success");

      // Редирект на главную страницу через 1 секунду
      setTimeout(() => {
        window.location.href = "/";
      }, 1000);
    } else {
      showNotification(data.message || "Неверный логин или пароль", "danger");
    }
  } catch (error) {
    console.error("Login error:", error);
    showNotification("Ошибка подключения к серверу", "danger");
  }
});

// Enter для отправки формы
document.getElementById("password").addEventListener("keypress", (e) => {
  if (e.key === "Enter") {
    document.getElementById("loginForm").dispatchEvent(new Event("submit"));
  }
});
