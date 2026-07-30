# === IMPORT === #

import os


# === ENVIRONMENT === #

DEBUG = os.environ.get("DJANGO__DEBUG", "false").lower() == "true"
SECRET_KEY = os.environ.get("DJANGO__SECRET_KEY", 'django-insecure-00000000000000000000000000000000000000000000000000')
CSRF_TRUSTED_ORIGINS = os.environ.get('CSRF_TRUSTED_ORIGINS', 'http://localhost:8080').split(',')
ALLOWED_HOSTS = ['*']
DATABASES = {
    'default': {
        "ENGINE": "django.db.backends.postgresql",
        "HOST": os.environ["DJANGO__DB_HOST"],
        "PORT": os.environ.get("DJANGO__DB_PORT", "5432"),
        "NAME": os.environ["DJANGO__DB_NAME"],
        "USER": os.environ["DJANGO__DB_USER"],
        "PASSWORD": os.environ["DJANGO__DB_PASSWORD"],
    }
}
TIME_ZONE = os.environ.get("DJANGO__TIME_ZONE", "UTC")
LANGUAGE_CODE = os.environ.get("DJANGO__LANGUAGE_CODE", "en-us")


# === CONFIG === #

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    #"public",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')
STATICFILES_DIRS = []

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
