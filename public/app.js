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

  const scheduleModal = document.getElementById("scheduleModal");
  if (scheduleModal) {
    scheduleModal.addEventListener("shown.bs.modal", loadTeacherSchedule);
  }
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

const DAY_NAMES = [
  "Воскресенье",
  "Понедельник",
  "Вторник",
  "Среда",
  "Четверг",
  "Пятница",
  "Суббота",
];
let studentScheduleSlots = [];
let currentScheduleStudentId = null;

function normalizeTimeSlot(timeSlot) {
  const [hour = "00", minute = "00"] = String(timeSlot || "").split(":");
  return `${hour.padStart(2, "0")}:${minute.padStart(2, "0")}`;
}

async function openStudentSchedule(studentId) {
  currentScheduleStudentId = studentId;
  const student = allStudents.find((s) => s.id === studentId);
  const name = student
    ? `${student.first_name} ${student.last_name || ""}`.trim()
    : "Ученик";
  document.getElementById("studentScheduleModalTitle").textContent =
    `Расписание: ${name}`;
  document.getElementById("studentScheduleId").value = studentId;
  document.getElementById("studentScheduleSlots").innerHTML =
    '<div class="text-muted small">Загрузка...</div>';

  try {
    const response = await fetch(`${API_URL}/student/${studentId}/schedule`, {
      headers: getAuthHeaders(),
    });
    const data = await response.json();
    if (data.status && data.data) {
      studentScheduleSlots = data.data.map((s) => ({
        day_of_week: s.day_of_week,
        time_slot: normalizeTimeSlot(s.time_slot),
      }));
    } else {
      studentScheduleSlots = [];
    }
  } catch (e) {
    studentScheduleSlots = [];
    showNotification("Ошибка загрузки расписания", "danger");
  }
  renderStudentScheduleSlots();
  initSchedulePickers();
  new bootstrap.Modal(document.getElementById("studentScheduleModal")).show();
}

function getSchedulePickerValues() {
  const dayBtn = document.querySelector(".day-picker-btn.active");
  const day = dayBtn ? parseInt(dayBtn.dataset.day, 10) : null;
  const h = document.querySelector("#scheduleHoursWheel .time-wheel-item.selected");
  const m = document.querySelector("#scheduleMinutesWheel .time-wheel-item.selected");
  const hour = h ? h.dataset.value : "10";
  const min = m ? m.dataset.value : "00";
  return { day, timeSlot: `${hour.padStart(2, "0")}:${min.padStart(2, "0")}` };
}

function initSchedulePickers() {
  const dayPicker = document.getElementById("scheduleDayPicker");
  if (!dayPicker) return;
  const timeSection = document.getElementById("scheduleTimeSection");
  const addBtn = document.getElementById("scheduleAddBtn");
  dayPicker.querySelectorAll(".day-picker-btn").forEach((btn) => {
    btn.classList.remove("active");
    btn.onclick = () => {
      dayPicker.querySelectorAll(".day-picker-btn").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      timeSection?.classList.remove("d-none");
      addBtn?.classList.remove("d-none");
    };
  });
  timeSection?.classList.add("d-none");
  addBtn?.classList.add("d-none");

  const hoursWheel = document.getElementById("scheduleHoursWheel");
  const minutesWheel = document.getElementById("scheduleMinutesWheel");
  if (!hoursWheel || !minutesWheel) return;

  hoursWheel.innerHTML = "";
  for (let i = 7; i <= 21; i++) {
    const div = document.createElement("div");
    div.className = "time-wheel-item";
    div.dataset.value = String(i);
    div.textContent = String(i).padStart(2, "0");
    hoursWheel.appendChild(div);
  }
  minutesWheel.innerHTML = "";
  for (let i = 0; i < 60; i += 5) {
    const div = document.createElement("div");
    div.className = "time-wheel-item";
    div.dataset.value = String(i).padStart(2, "0");
    div.textContent = String(i).padStart(2, "0");
    minutesWheel.appendChild(div);
  }

  const itemHeight = 34;
  const padding = 42;

  const updateSelection = (wheelEl) => {
    const items = wheelEl.querySelectorAll(".time-wheel-item");
    const center = wheelEl.scrollTop + wheelEl.clientHeight / 2 - itemHeight / 2;
    items.forEach((it) => it.classList.remove("selected"));
    for (let i = 0; i < items.length; i++) {
      const top = padding + i * itemHeight;
      if (top <= center && center < top + itemHeight) {
        items[i].classList.add("selected");
        break;
      }
    }
  };

  const scrollToSelected = (wheelEl, value) => {
    const items = wheelEl.querySelectorAll(".time-wheel-item");
    const idx = Array.from(items).findIndex((it) => it.dataset.value === value);
    if (idx >= 0) {
      wheelEl.scrollTop = padding + idx * itemHeight - wheelEl.clientHeight / 2 + itemHeight / 2;
    }
    updateSelection(wheelEl);
  };

  [hoursWheel, minutesWheel].forEach((w) => {
    w.onscroll = () => updateSelection(w);
  });

  scrollToSelected(hoursWheel, "10");
  scrollToSelected(minutesWheel, "00");
}

function addScheduleSlot() {
  const { day, timeSlot } = getSchedulePickerValues();
  if (day === null) {
    showNotification("Сначала выберите день недели", "warning");
    return;
  }
  const normalizedTime = normalizeTimeSlot(timeSlot);
  const alreadyExists = studentScheduleSlots.some(
    (slot) =>
      Number(slot.day_of_week) === Number(day) &&
      normalizeTimeSlot(slot.time_slot) === normalizedTime,
  );
  if (alreadyExists) {
    showNotification("Это время уже есть в расписании", "warning");
    return;
  }
  studentScheduleSlots.push({ day_of_week: day, time_slot: normalizedTime });
  saveStudentSchedule(false);
  renderStudentScheduleSlots();
}

function removeScheduleSlot(index) {
  studentScheduleSlots.splice(index, 1);
  saveStudentSchedule(false);
  renderStudentScheduleSlots();
}

function renderStudentScheduleSlots() {
  const container = document.getElementById("studentScheduleSlots");
  if (studentScheduleSlots.length === 0) {
    container.innerHTML =
      '<div class="text-muted small">Нет слотов. Добавьте время занятий.</div>';
    return;
  }
  container.innerHTML = studentScheduleSlots
    .map(
      (s, i) => {
        const timeStr = (s.time_slot || "").split(":").slice(0, 2).join(":");
        return `
    <div class="list-group-item d-flex justify-content-between align-items-center py-2">
      <span>${DAY_NAMES[s.day_of_week]} — <strong>${timeStr || s.time_slot}</strong></span>
      <button type="button" class="btn btn-outline-danger btn-sm" onclick="removeScheduleSlot(${i})">
        <i class="bi bi-trash"></i>
      </button>
    </div>
  `;
      },
    )
    .join("");
}

async function saveStudentSchedule(closeModal = true) {
  const id = document.getElementById("studentScheduleId").value;
  if (!id) return;
  try {
    const response = await fetch(`${API_URL}/student/${id}/schedule`, {
      method: "PUT",
      headers: getAuthHeaders(),
      body: JSON.stringify({ slots: studentScheduleSlots }),
    });
    const data = await response.json();
    if (data.status) {
      showNotification("Расписание сохранено", "success");
      if (closeModal) {
        bootstrap.Modal.getInstance(
          document.getElementById("studentScheduleModal"),
        )?.hide();
      }
    } else {
      showNotification(data.message || "Ошибка сохранения", "danger");
    }
  } catch (e) {
    showNotification("Ошибка при сохранении расписания", "danger");
    console.error(e);
  }
}

async function loadTeacherSchedule() {
  const container = document.getElementById("teacherScheduleContent");
  if (!container) return;
  container.innerHTML = '<div class="text-muted small">Загрузка...</div>';

  const daySlots = {};
  for (let d = 0; d <= 6; d++) daySlots[d] = [];

  try {
    for (let day = 0; day <= 6; day++) {
      const resp = await fetch(`${API_URL}/schedule?day=${day}`, {
        headers: getAuthHeaders(),
      });
      const data = await resp.json();
      if (data.status && data.data) {
        daySlots[day] = data.data;
      }
    }

    const dayOrder = [1, 2, 3, 4, 5, 6, 0];
    let html = '<div class="accordion teacher-schedule-accordion" id="teacherScheduleAccordion">';
    let hasAny = false;

    for (const d of dayOrder) {
      const slots = daySlots[d] || [];
      const dayName = DAY_NAMES[d];
      const sortedSlots = [...slots].sort((a, b) =>
        (a.time_slot || "").localeCompare(b.time_slot || "")
      );
      const count = sortedSlots.length;
      if (count > 0) hasAny = true;

      const slotsHtml =
        count === 0
          ? '<div class="text-muted small">На этот день записей нет</div>'
          : sortedSlots
              .map((s) => {
                const student = allStudents.find((st) => st.id === s.student_id);
                const name = student
                  ? `${student.first_name} ${student.last_name || ""}`.trim()
                  : `#${s.student_id}`;
                const timeStr = (s.time_slot || "").split(":").slice(0, 2).join(":");
                return `<div class="schedule-slot-row">
                <span class="time-badge">${timeStr || s.time_slot}</span>
                <span>${name}</span>
              </div>`;
              })
              .join("");

      const collapseId = `teacherScheduleDay${d}`;
      const headerId = `teacherScheduleDayHeading${d}`;
      let loadClass = "schedule-load-empty";
      if (count >= 1 && count <= 3) loadClass = "schedule-load-ok";
      else if (count >= 4) loadClass = "schedule-load-heavy";
      const expanded = "false";
      const showClass = "";
      html += `
        <div class="accordion-item ${loadClass}">
          <h2 class="accordion-header" id="${headerId}">
            <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#${collapseId}" aria-expanded="${expanded}" aria-controls="${collapseId}">
              <span>${dayName}</span>
              <span class="schedule-day-count">${count}</span>
            </button>
          </h2>
          <div id="${collapseId}" class="accordion-collapse collapse ${showClass}" aria-labelledby="${headerId}">
            <div class="accordion-body">
              ${slotsHtml}
            </div>
          </div>
        </div>
      `;
    }
    html += "</div>";
    container.innerHTML = hasAny ? html : '<div class="text-muted small">Расписание пусто</div>';
  } catch (e) {
    container.innerHTML = '<div class="text-muted small text-danger">Ошибка загрузки</div>';
    console.error(e);
  }
}

function showNotification(message, type = "success") {
  if (type !== "danger") {
    return;
  }
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
                        <button class="btn btn-outline-primary btn-sm" onclick="openStudentSchedule(${
                          student.id
                        })">
                            <i class="bi bi-calendar-week"></i> Расписание
                        </button>
                    </div>
                </div>
                <div class="card-footer d-flex justify-content-end gap-2 py-2">
                    <button class="btn btn-outline-primary btn-sm" onclick="editStudent(${
                      student.id
                    })" title="Редактировать">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-outline-danger btn-sm" onclick="deleteStudent(${
                      student.id
                    })" title="Удалить">
                        <i class="bi bi-trash"></i>
                    </button>
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
    const toNumber = (value) => {
      const num = Number(value);
      return Number.isFinite(num) ? num : 0;
    };

    let completedLessons = 0;
    let remainingLessons = 0;
    let missedLessons = 0;

    students.forEach((s) => {
      const total = Math.max(0, toNumber(s.total_lessons));
      const remaining = Math.min(
        total,
        Math.max(0, toNumber(s.remaining_lessons)),
      );
      let missed = Math.max(0, toNumber(s.missed_classes));

      if (total > 0 && missed > total) {
        missed = 0;
      }

      const completed = Math.max(0, total - remaining);
      completedLessons += completed;
      remainingLessons += remaining;
      missedLessons += missed;
    });

    lessonsChart.data.datasets[0].data = [
      completedLessons,
      remainingLessons,
      missedLessons,
    ];

    const lessonsValues = [completedLessons, remainingLessons, missedLessons];
    const maxLessonsValue = Math.max(...lessonsValues);
    const axisMax = Math.max(1, Math.ceil(maxLessonsValue * 1.2));
    if (lessonsChart.options.scales?.y) {
      lessonsChart.options.scales.y.beginAtZero = true;
      lessonsChart.options.scales.y.max = axisMax;
      lessonsChart.options.scales.y.ticks = {
        stepSize: axisMax <= 5 ? 1 : Math.ceil(axisMax / 5),
        callback: (value) => value.toLocaleString("ru-RU"),
      };
    }
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
