FROM python:3.10.20-trixie as app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

EXPOSE 8000

RUN apt-get update --yes --quiet \
    && apt-get install --yes --quiet --no-install-recommends \
        libpq-dev \
        python3-dev \
        musl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /application

COPY . .

RUN pip install --no-cache-dir --no-warn-script-location --upgrade pip \
    && pip install --no-cache-dir --no-warn-script-location -r requirements.txt

RUN python3 manage.py collectstatic --noinput

CMD ["gunicorn", "-c", "start_gunicorn.py", "config.wsgi:application"]

FROM nginx:1.31.2-trixie AS nginx

#COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=app \
    /application/static \
    /usr/share/nginx/html/static
