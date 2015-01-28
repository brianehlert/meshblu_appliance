module.exports = {
  port: 3000,
  log: true,
  // MongoDB has been installed
  mongo: {
    databaseUrl: "mongodb://localhost:27017/meshblu"
  },
  // Redis has been installed
  redis: {
    host: "localhost",
    port: "6379"
  },
  // this skynet cloud instance / object uuid - each one should be unique - this should be auto generated on very first boot
  // uuid: '',
  // token: '',
  // broadcastActivity: false,  
  // if you want to resolve message up to another skynet server:
  // this should be able to be set through some interface / console of the appliance
  parentConnection: {
  //  uuid: '',
  //  token: '',
  //  server: 'skynet.im',
  //  port: 80
  },
  coap: {
    port: 5683,
    host: "localhost"
  },
  //these settings are for the node mqtt server, and mqtt client
  mqtt: {
    databaseUrl: "mongodb://localhost:27017/mqtt",
    port: 1883,
    skynetPass: "reallylongstringsameasmeshbluserver"
  }
};
