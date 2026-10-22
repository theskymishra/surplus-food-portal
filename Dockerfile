FROM nginx:alpine

ARG FAULTY=false

COPY index.html /usr/share/nginx/html/index.html

RUN printf 'OK\n' > /usr/share/nginx/html/health.html \
    && if [ "$FAULTY" = "true" ]; then \
        rm /usr/share/nginx/html/health.html; \
    fi

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]