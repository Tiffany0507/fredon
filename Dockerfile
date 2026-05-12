FROM tomcat:9.0-jdk17

RUN sed -i 's/<Server port="8005"/<Server port="-1"/' /usr/local/tomcat/conf/server.xml

# Supprimer l'app ROOT par défaut
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copier le contenu web (JSP, CSS, etc.)
COPY src/main/webapp/ /usr/local/tomcat/webapps/ROOT/

# Copier les classes compilées
COPY build/classes/ /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/

EXPOSE 8080

CMD ["catalina.sh", "run"]
