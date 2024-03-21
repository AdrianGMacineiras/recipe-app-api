#Version 3.9 de python version de alpine, ideal para contenedores por que no tiene dependencias y es eficiente para docker
FROM python:3.9-alpine3.13
#Quien mantiene el docker
LABEL maintainer="adrian"

#Recomendado cuando se corre python en un contenedor, no quiere buffer del output, que se imprima en la consola y no haya retrasos
ENV PYTHONUNBUFFERED 1

#Copiar requirements de local al docker e instalar lo que requiera python, lo mismo con app
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
#Directorio por defecto donde se van a ejecutar los comandos cuando ejecutemos los comandos en nuestro docker
WORKDIR /app
EXPOSE 8000

# Genera un argumento llamado DEV y lo inicializa a falso.
ARG DEV=false

#Corre el comando en la imagen alpine
#Primer comando crea un espacio virtual donde guardaremos nuestras dependencias
RUN python -m venv /py && \
    #Upgrade nuestro espacio virtual
    /py/bin/pip install --upgrade pip && \
    # Instalar cliente postgresql
    apk add --update --no-cache postgresql-client &&\
    # Paquete de dependencia virtual
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev &&\
    #Installamos el fichero de requerimientos que copiamos previamente
    /py/bin/pip install -r /tmp/requirements.txt && \
    # Si el argumento DEV es true se instalan las dependencias de desarrollo
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    #Eliminamos el fichero tmp por que no queremos dependencias extras para tener el docker lo más ligero posible
    rm -rf /tmp && \
    # Borrar los paquetes virtuales
    apk del .tmp-build-deps && \
    #Añade un nuevo user en nuestra imagen, por que es buena practica no usar el usuario root
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

#
ENV PATH="/py/bin:$PATH" 

USER django-user