from django.db import models


class Contact(models.Model):
    """联系人模型"""
    name = models.CharField('姓名', max_length=50)
    phone = models.CharField('手机号', max_length=20, unique=True)
    email = models.EmailField('邮箱', blank=True, default='')
    address = models.CharField('地址', max_length=200, blank=True, default='')
    remark = models.TextField('备注', blank=True, default='')
    created_at = models.DateTimeField('创建时间', auto_now_add=True)
    updated_at = models.DateTimeField('更新时间', auto_now=True)

    class Meta:
        db_table = 'contacts'
        ordering = ['-created_at']
        verbose_name = '联系人'
        verbose_name_plural = verbose_name

    def __str__(self):
        return f'{self.name}({self.phone})'
