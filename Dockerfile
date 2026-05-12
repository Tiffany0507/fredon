FROM tomcat:9.0-jdk17

RUN sed -i 's/<Server port="8005"/<Server port="-1"/' /usr/local/tomcat/conf/server.xml

RUN rm -rf /usr/local/tomcat/webapps/ROOT

COPY src/main/webapp/ /usr/local/tomcat/webapps/ROOT/

RUN mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/classes

COPY src/main/java/ /tmp/src/

RUN find /tmp/src -name "*.java" > /tmp/sources.txt && \
    javac -cp /usr/local/tomcat/lib/servlet-api.jar \
          -d /usr/local/tomcat/webapps/ROOT/WEB-INF/classes \
          @/tmp/sources.txt

EXPOSE 8080
CMD ["catalina.sh", "run"]
