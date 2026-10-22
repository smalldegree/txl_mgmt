import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

export const contactApi = {
  // 列表，支持搜索与排序
  list(params = {}) {
    return api.get('/contacts/', { params })
  },
  // 新建
  create(data) {
    return api.post('/contacts/', data)
  },
  // 详情
  retrieve(id) {
    return api.get(`/contacts/${id}/`)
  },
  // 部分更新
  update(id, data) {
    return api.patch(`/contacts/${id}/`, data)
  },
  // 删除
  remove(id) {
    return api.delete(`/contacts/${id}/`)
  },
}

export default api
