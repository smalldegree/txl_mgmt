from django.core.management.base import BaseCommand

from contacts.models import Contact

SURNAMES = ['赵', '钱', '孙', '李', '周', '吴', '郑', '王', '冯', '陈',
            '褚', '卫', '蒋', '沈', '韩', '杨', '朱', '秦', '尤', '许',
            '何', '吕', '施', '张', '孔', '曹', '严', '华', '金', '魏']

GIVEN_NAMES = ['伟', '芳', '娜', '敏', '静', '丽', '强', '磊', '军', '洋']

CITIES = ['北京市', '上海市', '广州市', '深圳市', '杭州市',
          '南京市', '成都市', '武汉市', '西安市', '重庆市']


class Command(BaseCommand):
    help = '生成 300 条测试联系人数据（幂等，可重复执行）'

    def handle(self, *args, **options):
        total = 300
        contacts = []
        for i in range(total):
            surname = SURNAMES[i % len(SURNAMES)]
            given = GIVEN_NAMES[i // len(SURNAMES)]
            contacts.append(Contact(
                name=f'{surname}{given}',
                phone=f'139{i + 1:08d}',
                email=f'test{i + 1:03d}@example.com',
                address=CITIES[i % len(CITIES)],
                remark=f'测试数据第 {i + 1} 条',
            ))

        Contact.objects.bulk_create(contacts, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS(f'测试数据已生成，当前共 {Contact.objects.count()} 条'))
