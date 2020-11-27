    const VectorAPI = require("./index");
    var vector = new VectorAPI({
        VECTOR_SN: "00123456",
        VECTOR_NAME: "Vector-XXXX",
        VECTOR_IP: "192.168.0.XXX,
        VECTOR_BEARER_TOKEN: "xxxxxxxxxxxxxxxx==",
        VECTOR_CRT: "Vector-XXXX-00123456.cert",
        DEBUG_LEVEL: "info" // Not found in the sdk_config.ini. Available options: "trace", "debug", "info", "error", "fatal"
    });
    
    // List out all available methods
    // Should be the same (or mostly the same) as: https://developer.anki.com/vector/docs/generated/anki_vector.messaging.client.html
    var routes = vector.listMethods();
    routes.forEach((route) => {
        console.log(`Route ${route.name} : `);
        console.log(`         req fields: ${JSON.stringify(route.requestFields)}`);
        console.log(`         res fields: ${JSON.stringify(route.requestFields)}`);
    });
    
    // Actually call a method
    console.log("Asking Vector about his protocol version...");
    vector.client.ProtocolVersion({"client_version": vector.VECTOR_CLIENT_VERSION, "min_host_version": vector.VECTOR_MIN_HOST_VERSION}, (err, result) => {
        if (err){
            console.log("Error", err);
        }
        console.log(result);
    });