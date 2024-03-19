FROM gcr.io/forgerock-io/am-cdk/pit1:7.5.0-latest-postcommit

ARG CONFIG_PROFILE=cdk
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY  --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /home/forgerock/openam/

COPY --chown=forgerock:root *.sh /home/forgerock/
COPY --chown=forgerock:root *.jar /usr/local/tomcat/webapps/am/WEB-INF/lib/
WORKDIR /home/forgerock
RUN rm -rf /home/forgerock/base/config/services/realm/root/amdatastoreservice/1.0/globalconfig/default/datastorecontainer/*.json
RUN rm -rf /home/forgerock/base/config/services/realm/root/amdatastoreservice/1.0/organizationconfig/default.json
# If you want to debug AM uncomment these lines:
#ENV JPDA_TRANSPORT=dt_socket
#ENV JPDA_ADDRESS *:9009
