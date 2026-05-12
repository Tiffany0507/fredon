FROM tomcat:9.0-jdk17

# Désactiver le port shutdown pour éviter le conflit avec Render
RUN sed -i 's/<Server port="8005"/<Server port="-1"/' /usr/local/tomcat/conf/server.xml

COPY quickchat.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
