// API Base URL
const API_URL = "/api/v1";
const paidToggleRegistry = {};
let allStudents = [];
const filters = {
  sort: "created_desc",
  status: "all",
  remaining: "all",
};

document.addEventListener("DOMContentLoaded", () => {
  checkAuth();
  setupPaidToggle("addPaidToggle", "addIsPaid");
  setupPaidToggle("editPaidToggle", "editIsPaid");
  const sortSelect = document.getElementById("sortFilter");
  const statusSelect = document.getElementById("statusFilter");
  const remainingSelect = document.getElementById("remainingFilter");

  if (sortSelect) {
    sortSelect.addEventListener("change", (e) => {
      filters.sort = e.target.value;
      renderStudents();
    });
  }

  if (statusSelect) {
    statusSelect.addEventListener("change", (e) => {
      filters.status = e.target.value;
      renderStudents();
    });
  }

  if (remainingSelect) {
    remainingSelect.addEventListener("change", (e) => {
      filters.remaining = e.target.value;
      renderStudents();
    });
  }

  loadStudents();
});

function checkAuth() {
  const token = localStorage.getItem("auth_token");
  if (!token) {
    window.location.href = "/login.html";
    return;
  }

  const teacherName = localStorage.getItem("teacher_name");
  if (teacherName) {
    document.getElementById("teacherNameText").textContent = teacherName;
  }
}

function getAuthHeaders() {
  const token = localStorage.getItem("auth_token");
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  };
}

function logout() {
  localStorage.removeItem("auth_token");
  localStorage.removeItem("teacher_name");
  window.location.href = "/login.html";
}

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

async function loadStudents() {
  try {
    const response = await fetch(`${API_URL}/students`, {
      headers: getAuthHeaders(),
    });

    if (response.status === 401) {
      localStorage.removeItem("auth_token");
      localStorage.removeItem("teacher_name");
      window.location.href = "/login.html";
      return;
    }

    const data = await response.json();

    if (!data.status) {
      showNotification("Ошибка загрузки студентов", "danger");
      return;
    }

    allStudents = data.data || [];
    renderStudents();
  } catch (error) {
    showNotification("Ошибка подключения к серверу", "danger");
    console.error(error);
  }
}

function renderStudents() {
  const filtered = applyFilters(allStudents);
  displayStudents(filtered);
}

function applyFilters(students) {
  let result = [...students];

  // status filter
  if (filters.status === "paid") {
    result = result.filter((s) => s.is_paid);
  } else if (filters.status === "unpaid") {
    result = result.filter((s) => !s.is_paid);
  }

  // remaining lessons filter
  if (filters.remaining === "low") {
    result = result.filter(
      (s) => s.remaining_lessons <= 2 && s.remaining_lessons > 0
    );
  } else if (filters.remaining === "zero") {
    result = result.filter((s) => s.remaining_lessons === 0);
  }

  // sorting
  result.sort((a, b) => {
    switch (filters.sort) {
      case "remaining_asc":
        return a.remaining_lessons - b.remaining_lessons;
      case "remaining_desc":
        return b.remaining_lessons - a.remaining_lessons;
      case "paid_desc":
        return (b.paid_amount || 0) - (a.paid_amount || 0);
      case "created_desc":
      default:
        return new Date(b.created_at) - new Date(a.created_at);
    }
  });

  return result;
}

function displayStudents(students) {
  const container = document.getElementById("studentsList");

  if (students.length === 0) {
    container.innerHTML = `
            <div class="col-12 text-center">
                <p class="text-muted">Нет студентов. Добавьте первого!</p>
            </div>
        `;
    return;
  }

  container.innerHTML = students
    .map(
      (student) => `
        <div class="col-md-6 col-lg-4 mb-4">
            <div class="card student-card">
                <div class="card-body">
                    <div class="student-meta">
                        <div>
                            <h5 class="card-title">
                                ${student.first_name} ${student.last_name || ""}
                                ${
                                  student.is_paid
                                    ? '<i class="bi bi-check-circle-fill text-success ms-1"></i>'
                                    : '<i class="bi bi-x-circle-fill text-danger ms-1"></i>'
                                }
                            </h5>
                            ${
                              student.middle_name
                                ? `<p class="text-muted mb-0">${student.middle_name}</p>`
                                : ""
                            }
                        </div>
                        <div class="student-chip ${
                          student.missed_classes > 0 ? "" : "muted"
                        }" title="Количество пропусков">
                            <i class="bi bi-exclamation-diamond-fill"></i>
                            <span>${student.missed_classes}</span>
                        </div>
                    </div>

                    <div class="mb-3 d-flex gap-2 flex-wrap">
                        <span class="badge badge-progress badge-lessons">
                            <i class="bi bi-book"></i>
                            Проведено: ${
                              student.total_lessons - student.remaining_lessons
                            } / ${student.total_lessons}
                        </span>
                        <span class="badge badge-remaining badge-lessons ${
                          student.remaining_lessons <= 1 ? "critical" : ""
                        }">
                            <i class="bi bi-clock"></i>
                            Осталось: ${student.remaining_lessons}
                        </span>
                    </div>

                    <p class="card-text mb-3">
                        <strong>Оплата:</strong> ${student.paid_amount} тг
                    </p>
                    
                    <div class="d-grid gap-2">
                        <button class="btn btn-success btn-sm" onclick="completeLesson(${
                          student.id
                        })" 
                                ${
                                  student.remaining_lessons <= 0
                                    ? "disabled"
                                    : ""
                                }>
                            <i class="bi bi-check-lg"></i> Урок проведен
                        </button>
                        <button class="btn btn-warning btn-sm" onclick="markMissed(${
                          student.id
                        })">
                            <i class="bi bi-x-lg"></i> Отметить пропуск
                        </button>
                        <div class="btn-group" role="group">
                            <button class="btn btn-outline-primary btn-sm" onclick="editStudent(${
                              student.id
                            })">
                                <i class="bi bi-pencil"></i> Редактировать
                            </button>
                            <button class="btn btn-outline-danger btn-sm" onclick="deleteStudent(${
                              student.id
                            })">
                                <i class="bi bi-trash"></i> Удалить
                            </button>
                        </div>
                    </div>
                </div>
                <div class="card-footer text-muted small">
                    Создан: ${new Date(student.created_at).toLocaleDateString(
                      "ru-RU"
                    )}
                </div>
            </div>
        </div>
    `
    )
    .join("");
}

async function addStudent() {
  const student = {
    first_name: document.getElementById("addFirstName").value,
    last_name: document.getElementById("addLastName").value,
    middle_name: document.getElementById("addMiddleName").value,
    total_lessons: parseInt(document.getElementById("addTotalLessons").value),
    remaining_lessons: parseInt(
      document.getElementById("addTotalLessons").value
    ),
    paid_amount: parseInt(document.getElementById("addPaidAmount").value),
    missed_classes: 0,
    is_paid: document.getElementById("addIsPaid").value === "true",
  };

  try {
    const response = await fetch(`${API_URL}/students`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify(student),
    });

    const data = await response.json();

    if (data.status) {
      showNotification("Студент успешно добавлен!", "success");
      bootstrap.Modal.getInstance(
        document.getElementById("addStudentModal")
      ).hide();
      document.getElementById("addStudentForm").reset();
      setPaidValue("addIsPaid", false);
      loadStudents();
    } else {
      showNotification(data.message, "danger");
    }
  } catch (error) {
    showNotification("Ошибка при добавлении студента", "danger");
    console.error(error);
  }
}

async function editStudent(id) {
  try {
    const response = await fetch(`${API_URL}/student/${id}`, {
      headers: getAuthHeaders(),
    });
    const data = await response.json();

    if (!data.status) {
      showNotification("Студент не найден", "danger");
      return;
    }

    const student = data.data;
    document.getElementById("editStudentId").value = student.id;
    document.getElementById("editFirstName").value = student.first_name;
    document.getElementById("editLastName").value = student.last_name || "";
    document.getElementById("editMiddleName").value = student.middle_name || "";
    document.getElementById("editTotalLessons").value = student.total_lessons;
    document.getElementById("editRemainingLessons").value =
      student.remaining_lessons;
    document.getElementById("editPaidAmount").value = student.paid_amount;
    document.getElementById("editMissedClasses").value = student.missed_classes;
    setPaidValue("editIsPaid", student.is_paid);

    new bootstrap.Modal(document.getElementById("editStudentModal")).show();
  } catch (error) {
    showNotification("Ошибка загрузки данных студента", "danger");
    console.error(error);
  }
}

async function updateStudent() {
  const id = document.getElementById("editStudentId").value;
  const student = {
    first_name: document.getElementById("editFirstName").value,
    last_name: document.getElementById("editLastName").value,
    middle_name: document.getElementById("editMiddleName").value,
    total_lessons: parseInt(document.getElementById("editTotalLessons").value),
    remaining_lessons: parseInt(
      document.getElementById("editRemainingLessons").value
    ),
    paid_amount: parseInt(document.getElementById("editPaidAmount").value),
    missed_classes: parseInt(
      document.getElementById("editMissedClasses").value
    ),
    is_paid: document.getElementById("editIsPaid").value === "true",
  };

  try {
    const response = await fetch(`${API_URL}/student/${id}`, {
      method: "PUT",
      headers: getAuthHeaders(),
      body: JSON.stringify(student),
    });

    const data = await response.json();

    if (data.status) {
      showNotification("Данные студента обновлены!", "success");
      bootstrap.Modal.getInstance(
        document.getElementById("editStudentModal")
      ).hide();
      loadStudents();
    } else {
      showNotification(data.message, "danger");
    }
  } catch (error) {
    showNotification("Ошибка при обновлении данных", "danger");
    console.error(error);
  }
}

async function completeLesson(id) {
  try {
    const response = await fetch(`${API_URL}/student/${id}/complete-lesson`, {
      method: "POST",
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (data.status) {
      showNotification("Урок отмечен как проведенный!", "success");
      loadStudents();
    } else {
      showNotification(data.message, "danger");
    }
  } catch (error) {
    showNotification("Ошибка при отметке урока", "danger");
    console.error(error);
  }
}

async function markMissed(id) {
  try {
    const response = await fetch(`${API_URL}/student/${id}/mark-missed`, {
      method: "POST",
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (data.status) {
      showNotification("Пропуск отмечен!", "warning");
      loadStudents();
    } else {
      showNotification(data.message, "danger");
    }
  } catch (error) {
    showNotification("Ошибка при отметке пропуска", "danger");
    console.error(error);
  }
}

function deleteStudent(id) {
  document.getElementById("deleteStudentId").value = id;
  new bootstrap.Modal(document.getElementById("deleteConfirmModal")).show();
}

async function confirmDelete() {
  const id = document.getElementById("deleteStudentId").value;

  try {
    const response = await fetch(`${API_URL}/student/${id}`, {
      method: "DELETE",
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (data.status) {
      showNotification("Студент удален!", "info");
      bootstrap.Modal.getInstance(
        document.getElementById("deleteConfirmModal")
      ).hide();
      loadStudents();
    } else {
      showNotification(data.message, "danger");
    }
  } catch (error) {
    showNotification("Ошибка при удалении студента", "danger");
    console.error(error);
  }
}

function setupPaidToggle(buttonId, inputId) {
  const button = document.getElementById(buttonId);
  const input = document.getElementById(inputId);
  if (!button || !input) return;

  const syncUI = () => {
    const isPaid = input.value === "true";
    if (isPaid) {
      button.classList.remove("paid-state-unpaid");
      button.classList.add("paid-state-paid");
      button.innerHTML = '<i class="bi bi-cash-stack"></i> Оплачено';
    } else {
      button.classList.remove("paid-state-paid");
      button.classList.add("paid-state-unpaid");
      button.innerHTML =
        '<i class="bi bi-exclamation-octagon-fill"></i> Не оплачено';
    }
  };

  button.addEventListener("click", () => {
    input.value = input.value === "true" ? "false" : "true";
    syncUI();
  });

  paidToggleRegistry[inputId] = syncUI;
  syncUI();
}

function setPaidValue(inputId, value) {
  const input = document.getElementById(inputId);
  if (!input) return;
  input.value = value ? "true" : "false";
  if (paidToggleRegistry[inputId]) {
    paidToggleRegistry[inputId]();
  }
}
