// API Base URL
const API_URL = "/api/v1";
const paidToggleRegistry = {};
let allStudents = [];
const filters = {
  status: "all",
};

document.addEventListener("DOMContentLoaded", () => {
  checkAuth();
  setupPaidToggle("addPaidToggle", "addIsPaid");
  setupPaidToggle("editPaidToggle", "editIsPaid");
  const paymentQuickButtons = document.querySelectorAll(
    "[data-payment-filter]",
  );

  if (paymentQuickButtons.length) {
    paymentQuickButtons.forEach((btn) => {
      btn.addEventListener("click", () => {
        const value = btn.getAttribute("data-payment-filter");
        if (filters.status === value) return;
        filters.status = value;
        updateQuickPaymentFilter(value);
        renderStudents();
      });
    });
    updateQuickPaymentFilter(filters.status);
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
    const nameElement = document.getElementById("teacherNameText");
    const modalNameElement = document.getElementById("userModalName");
    if (nameElement) {
      nameElement.textContent = teacherName;
    }
    if (modalNameElement) {
      modalNameElement.textContent = teacherName;
    }
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
  displayGridStudents(filtered);
  updateQuickPaymentFilter(filters.status);
}

function applyFilters(students) {
  let result = [...students];

  // status filter
  if (filters.status === "paid") {
    result = result.filter((s) => s.is_paid);
  } else if (filters.status === "unpaid") {
    result = result.filter((s) => !s.is_paid);
  }

  // default sorting: недавние сверху
  result.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return result;
}

function updateQuickPaymentFilter(value) {
  const buttons = document.querySelectorAll("[data-payment-filter]");
  if (!buttons.length) return;
  buttons.forEach((btn) => {
    const btnValue = btn.getAttribute("data-payment-filter");
    btn.classList.toggle("active", btnValue === value);
  });
}

function displayGridStudents(students) {
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
                      "ru-RU",
                    )}
                </div>
            </div>
        </div>
    `,
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
      document.getElementById("addTotalLessons").value,
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
        document.getElementById("addStudentModal"),
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
      document.getElementById("editRemainingLessons").value,
    ),
    paid_amount: parseInt(document.getElementById("editPaidAmount").value),
    missed_classes: parseInt(
      document.getElementById("editMissedClasses").value,
    ),
    is_paid: document.getElementById("editIsPaid").value === "true",
  };

  await submitStudentUpdate(id, student, {
    onSuccess: () => {
      bootstrap.Modal.getInstance(
        document.getElementById("editStudentModal"),
      ).hide();
    },
  });
}

async function submitStudentUpdate(id, student, options = {}) {
  const { successMessage = "Данные студента обновлены!", onSuccess } = options;

  try {
    const response = await fetch(`${API_URL}/student/${id}`, {
      method: "PUT",
      headers: getAuthHeaders(),
      body: JSON.stringify(student),
    });

    const data = await response.json();

    if (data.status) {
      showNotification(successMessage, "success");
      if (typeof onSuccess === "function") {
        onSuccess(data);
      }
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
        document.getElementById("deleteConfirmModal"),
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

const monthNames = [
  "Январь",
  "Февраль",
  "Март",
  "Апрель",
  "Май",
  "Июнь",
  "Июль",
  "Август",
  "Сентябрь",
  "Октябрь",
  "Ноябрь",
  "Декабрь",
];

function formatNumber(num) {
  if (num === null || num === undefined || isNaN(num)) {
    return "0";
  }
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

async function loadMonthlySummary() {
  const summaryLabel = document.getElementById("monthlySummaryLabel");
  const summaryAmount = document.getElementById("monthlySummaryAmount");

  if (!summaryLabel || !summaryAmount) {
    return;
  }

  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  const monthName = monthNames[month - 1];

  // Сразу показываем текущий месяц
  summaryLabel.textContent = `За ${monthName}`;
  summaryAmount.textContent = "0₸";

  try {
    const response = await fetch(
      `${API_URL}/monthly-summary?year=${year}&month=${month}`,
      {
        headers: getAuthHeaders(),
      },
    );

    if (response.status === 401) {
      localStorage.removeItem("auth_token");
      localStorage.removeItem("teacher_name");
      window.location.href = "/login.html";
      return;
    }

    let amount = 0;

    if (response.ok) {
      try {
        const data = await response.json();

        if (data.status && data.data) {
          if (typeof data.data.total_amount === "number") {
            amount = data.data.total_amount;
          } else if (data.data.total_amount !== undefined) {
            amount = parseInt(data.data.total_amount) || 0;
          }
        }
      } catch (jsonError) {
        console.error("Ошибка парсинга JSON:", jsonError);
      }
    } else {
      console.warn(`HTTP error! status: ${response.status}`);
    }

    const formattedAmount = formatNumber(amount);
    summaryLabel.textContent = `За ${monthName}`;
    summaryAmount.textContent = `${formattedAmount}₸`;
  } catch (error) {
    console.error("Ошибка загрузки месячной сводки:", error);
    summaryLabel.textContent = `За ${monthName}`;
    summaryAmount.textContent = "0₸";
  }
}

// Инициализация графиков
let monthlyChart = null;
let statusChart = null;
let lessonsChart = null;

function initCharts() {
  // График динамики по месяцам (линейный)
  const monthlyCtx = document.getElementById("monthlyChart");
  if (monthlyCtx) {
    monthlyChart = new Chart(monthlyCtx, {
      type: "line",
      data: {
        labels: [
          "Янв",
          "Фев",
          "Мар",
          "Апр",
          "Май",
          "Июн",
          "Июл",
          "Авг",
          "Сен",
          "Окт",
          "Ноя",
          "Дек",
        ],
        datasets: [
          {
            label: "Доход (₸)",
            data: [],
            borderColor: "#5c6ac4",
            backgroundColor: "rgba(92, 106, 196, 0.1)",
            tension: 0.4,
            fill: true,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        resizeDelay: 200,
        plugins: {
          legend: {
            display: false,
          },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function (value) {
                return value.toLocaleString("ru-RU") + "₸";
              },
            },
          },
        },
      },
    });
  }

  // Круговой график статусов оплаты
  const statusCtx = document.getElementById("statusChart");
  if (statusCtx) {
    statusChart = new Chart(statusCtx, {
      type: "doughnut",
      data: {
        labels: ["Оплачено", "Не оплачено"],
        datasets: [
          {
            data: [0, 0],
            backgroundColor: ["#10b981", "#ef4444"],
            borderWidth: 0,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        resizeDelay: 200,
        plugins: {
          legend: {
            position: "bottom",
          },
        },
      },
    });
  }

  // Столбчатый график статистики уроков
  const lessonsCtx = document.getElementById("lessonsChart");
  if (lessonsCtx) {
    lessonsChart = new Chart(lessonsCtx, {
      type: "bar",
      data: {
        labels: ["Проведено", "Осталось", "Пропущено"],
        datasets: [
          {
            label: "Количество",
            data: [0, 0, 0],
            backgroundColor: ["#3b82f6", "#0ea5e9", "#f59e0b"],
            borderRadius: 8,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        resizeDelay: 200,
        plugins: {
          legend: {
            display: false,
          },
        },
        scales: {
          y: {
            beginAtZero: true,
          },
        },
      },
    });
  }
}

async function loadChartsData() {
  if (!monthlyChart || !statusChart || !lessonsChart) {
    return;
  }

  try {
    // Загружаем данные студентов для статистики
    const response = await fetch(`${API_URL}/students`, {
      headers: getAuthHeaders(),
    });

    if (!response.ok) return;

    const data = await response.json();
    if (!data.status || !data.data) return;

    const students = data.data;

    // Статистика по статусам оплаты
    const paidCount = students.filter((s) => s.is_paid).length;
    const unpaidCount = students.length - paidCount;
    statusChart.data.datasets[0].data = [paidCount, unpaidCount];
    statusChart.update();

    // Статистика уроков
    const completedLessons = students.reduce(
      (sum, s) => sum + (s.total_lessons - s.remaining_lessons),
      0,
    );
    const remainingLessons = students.reduce(
      (sum, s) => sum + s.remaining_lessons,
      0,
    );
    const missedLessons = students.reduce(
      (sum, s) => sum + s.missed_classes,
      0,
    );
    lessonsChart.data.datasets[0].data = [
      completedLessons,
      remainingLessons,
      missedLessons,
    ];
    lessonsChart.update();

    // Загружаем данные по месяцам (пример - можно расширить API)
    const now = new Date();
    const currentYear = now.getFullYear();
    const monthlyData = [];

    for (let month = 1; month <= 12; month++) {
      try {
        const monthResponse = await fetch(
          `${API_URL}/monthly-summary?year=${currentYear}&month=${month}`,
          {
            headers: getAuthHeaders(),
          },
        );
        if (monthResponse.ok) {
          const monthData = await monthResponse.json();
          monthlyData.push(
            monthData.status && monthData.data
              ? monthData.data.total_amount || 0
              : 0,
          );
        } else {
          monthlyData.push(0);
        }
      } catch (error) {
        monthlyData.push(0);
      }
    }

    monthlyChart.data.datasets[0].data = monthlyData;
    monthlyChart.update();
  } catch (error) {
    console.error("Ошибка загрузки данных для графиков:", error);
  }
}

// Инициализация графиков при открытии модального окна
document.addEventListener("DOMContentLoaded", () => {
  const summaryModal = document.getElementById("summaryModal");
  if (summaryModal) {
    summaryModal.addEventListener("shown.bs.modal", () => {
      // Ждём завершения анимации модалки, чтобы не было мерцания
      setTimeout(() => {
        if (!monthlyChart) {
          initCharts();
        }
        if (monthlyChart) monthlyChart.resize();
        if (statusChart) statusChart.resize();
        if (lessonsChart) lessonsChart.resize();
        loadChartsData();
      }, 350);
    });
  }
});
