from django.contrib import admin

from .models import Contact


@admin.register(Contact)
class ContactAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'phone', 'email', 'created_at']
    search_fields = ['name', 'phone', 'email']
    list_per_page = 20
