<template>
  <div class="page">
    <header class="header">
      <h1>通讯录管理系统</h1>
      <span class="subtitle">共 {{ total }} 位联系人</span>
    </header>

    <!-- 工具栏 -->
    <div class="toolbar">
      <input
        v-model.trim="keyword"
        class="search-input"
        type="search"
        placeholder="搜索姓名 / 手机号 / 邮箱"
        @input="onSearchInput"
      />
      <button class="btn btn-primary" @click="openCreate">+ 新建联系人</button>
    </div>

    <!-- 列表 -->
    <div class="table-wrap" v-loading="loading">
      <table class="table" v-if="!loading && contacts.length">
        <thead>
          <tr>
            <th>姓名</th>
            <th>手机号</th>
            <th>邮箱</th>
            <th>地址</th>
            <th>备注</th>
            <th>创建时间</th>
            <th class="col-actions">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in contacts" :key="c.id">
            <td>{{ c.name }}</td>
            <td>{{ c.phone }}</td>
            <td>{{ c.email || '-' }}</td>
            <td>{{ c.address || '-' }}</td>
            <td class="td-remark" :title="c.remark">{{ c.remark || '-' }}</td>
            <td>{{ formatTime(c.created_at) }}</td>
            <td class="col-actions">
              <button class="btn btn-sm" @click="openEdit(c)">编辑</button>
              <button class="btn btn-sm btn-danger" @click="onDelete(c)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else-if="!loading" class="empty">暂无联系人，点击右上角"新建联系人"添加</div>
      <div v-else class="empty">加载中...</div>
    </div>

    <!-- 分页 -->
    <div class="pagination" v-if="total > pageSize">
      <button class="btn" :disabled="page <= 1" @click="changePage(page - 1)">上一页</button>
      <span class="page-info">第 {{ page }} / {{ totalPages }} 页，共 {{ total }} 条</span>
      <button class="btn" :disabled="page >= totalPages" @click="changePage(page + 1)">下一页</button>
    </div>

    <!-- 编辑/新建弹窗 -->
    <div v-if="dialogVisible" class="modal-mask" @click.self="closeDialog">
      <div class="modal">
        <h2 class="modal-title">{{ isEdit ? '编辑联系人' : '新建联系人' }}</h2>
        <form class="form" @submit.prevent="onSubmit">
          <label class="form-item">
            <span class="form-label">姓名 <i class="req">*</i></span>
            <input v-model.trim="form.name" maxlength="50" placeholder="请输入姓名" />
            <span v-if="errors.name" class="form-error">{{ errors.name }}</span>
          </label>
          <label class="form-item">
            <span class="form-label">手机号 <i class="req">*</i></span>
            <input v-model.trim="form.phone" maxlength="20" placeholder="请输入手机号" />
            <span v-if="errors.phone" class="form-error">{{ errors.phone }}</span>
          </label>
          <label class="form-item">
            <span class="form-label">邮箱</span>
            <input v-model.trim="form.email" type="email" placeholder="请输入邮箱" />
            <span v-if="errors.email" class="form-error">{{ errors.email }}</span>
          </label>
          <label class="form-item">
            <span class="form-label">地址</span>
            <input v-model.trim="form.address" maxlength="200" placeholder="请输入地址" />
          </label>
          <label class="form-item">
            <span class="form-label">备注</span>
            <textarea v-model.trim="form.remark" rows="3" placeholder="请输入备注"></textarea>
          </label>
          <div class="modal-footer">
            <button type="button" class="btn" @click="closeDialog">取消</button>
            <button type="submit" class="btn btn-primary" :disabled="submitting">
              {{ submitting ? '保存中...' : '保存' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 轻提示 -->
    <transition name="fade">
      <div v-if="toast.visible" class="toast" :class="toast.type">{{ toast.message }}</div>
    </transition>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { contactApi } from './api'

const contacts = ref([])
const loading = ref(false)
const keyword = ref('')
const page = ref(1)
const pageSize = 20
const total = ref(0)
const totalPages = computed(() => Math.ceil(total.value / pageSize))

const dialogVisible = ref(false)
const isEdit = ref(false)
const editingId = ref(null)
const submitting = ref(false)
const form = reactive({ name: '', phone: '', email: '', address: '', remark: '' })
const errors = reactive({ name: '', phone: '', email: '' })

const toast = reactive({ visible: false, message: '', type: 'success' })
let toastTimer = null
function showToast(message, type = 'success') {
  toast.message = message
  toast.type = type
  toast.visible = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toast.visible = false), 2500)
}

// 加载列表
async function fetchContacts() {
  loading.value = true
  try {
    const params = { page: page.value }
    if (keyword.value) params.search = keyword.value
    const { data } = await contactApi.list(params)
    contacts.value = data.results
    total.value = data.count
  } catch (e) {
    showToast('加载失败，请检查后端服务', 'error')
  } finally {
    loading.value = false
  }
}

// 搜索防抖
let searchTimer = null
function onSearchInput() {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    page.value = 1
    fetchContacts()
  }, 300)
}

// 切换分页
function changePage(p) {
  if (p < 1 || p > totalPages.value) return
  page.value = p
  fetchContacts()
}

// 打开新建
function openCreate() {
  isEdit.value = false
  editingId.value = null
  resetForm()
  dialogVisible.value = true
}

// 打开编辑
function openEdit(c) {
  isEdit.value = true
  editingId.value = c.id
  Object.assign(form, {
    name: c.name,
    phone: c.phone,
    email: c.email,
    address: c.address,
    remark: c.remark,
  })
  clearErrors()
  dialogVisible.value = true
}

function closeDialog() {
  dialogVisible.value = false
}

function resetForm() {
  Object.assign(form, { name: '', phone: '', email: '', address: '', remark: '' })
  clearErrors()
}

function clearErrors() {
  errors.name = ''
  errors.phone = ''
  errors.email = ''
}

// 提交
async function onSubmit() {
  clearErrors()
  if (!form.name) errors.name = '姓名不能为空'
  if (!form.phone) errors.phone = '手机号不能为空'
  if (errors.name || errors.phone) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await contactApi.update(editingId.value, { ...form })
      showToast('更新成功')
    } else {
      await contactApi.create({ ...form })
      showToast('创建成功')
    }
    closeDialog()
    fetchContacts()
  } catch (e) {
    const data = e.response?.data
    if (data && typeof data === 'object') {
      errors.name = Array.isArray(data.name) ? data.name[0] : ''
      errors.phone = Array.isArray(data.phone) ? data.phone[0] : ''
      errors.email = Array.isArray(data.email) ? data.email[0] : ''
      if (!errors.name && !errors.phone && !errors.email) {
        showToast('保存失败', 'error')
      }
    } else {
      showToast('保存失败，请检查网络', 'error')
    }
  } finally {
    submitting.value = false
  }
}

// 删除
async function onDelete(c) {
  if (!window.confirm(`确定删除联系人「${c.name}」吗？`)) return
  try {
    await contactApi.remove(c.id)
    showToast('删除成功')
    fetchContacts()
  } catch (e) {
    showToast('删除失败', 'error')
  }
}

function formatTime(iso) {
  if (!iso) return '-'
  const d = new Date(iso)
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`
}

onMounted(() => fetchContacts())
</script>
