from rest_framework import filters, viewsets

from .models import Contact
from .serializers import ContactSerializer


class ContactViewSet(viewsets.ModelViewSet):
    """联系人 RESTful API

    GET    /api/contacts/       列表（支持 ?search= 搜索姓名/手机号/邮箱）
    POST   /api/contacts/       新建
    GET    /api/contacts/{id}/  详情
    PUT    /api/contacts/{id}/  全量更新
    PATCH  /api/contacts/{id}/  部分更新
    DELETE /api/contacts/{id}/  删除
    """
    queryset = Contact.objects.all()
    serializer_class = ContactSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'phone', 'email']
    ordering_fields = ['name', 'created_at', 'updated_at']
