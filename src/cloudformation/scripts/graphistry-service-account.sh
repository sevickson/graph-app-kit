#!/bin/bash
set -ex

SCRIPT="Get AWS Instance ID"
./hello-start.sh "$SCRIPT"


ADD_USER_SCRIPT="from nexus.users.models import User; user=User.objects.create_superuser(username='admin', email='admin@amazon.com', password='${INSTANCE_ID}', name='admin', is_active=True); print('made user')"
VERIFY_USER_SCRIPT="from allauth.account.models import EmailAddress; e = EmailAddress.objects.create(user=user, email='admin@amazon.com', primary=True, verified=True); e.save(); print('verified user')"
POST_SCRIPT = "CELERY_BROKER_URL=zz python manage.py shell && echo done || { echo fail && exit 1; }"

#FIXME Faster and safer by by a nexus ready check (migrations done => server started?)
( \
    cd "${GRAPHISTRY_HOME}" \
    && ( \
        until ( curl -fsS http://localhost/streamgl-gpu/secondary/gpu/health > /dev/null ); \
        do ( docker-compose ps && sleep 1 ); \
        done \
    ) && docker-compose exec -T nexus \
        bash -c \
          "source activate rapids && echo \"${ADD_USER_SCRIPT}; ${VERIFY_USER_SCRIPT}\" | ${POST_SCRIPT}" \
)

./hello-end.sh "$SCRIPT"