FROM ibmcom/datapower
ADD src/config/auto-startup.cfg /drouter/config/auto-startup.cfg
ADD src/cert/HIAL_Gateway/wsgateway.key /drouter/cert/HIAL_Gateway/wsgateway.key
ADD src/cert/HIAL_Gateway/wsgateway.crt /drouter/cert/HIAL_Gateway/wsgateway.crt
