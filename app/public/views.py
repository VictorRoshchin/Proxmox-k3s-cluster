from django.views.generic import TemplateView


class HelloWorldView(TemplateView):
    template_name = 'public/hello_world.html'
