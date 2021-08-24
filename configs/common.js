var common = {
  //log-level
  loglevel:'DEBUG',
  logfilename:'default.log',
  logtypes:['console','file'],
  /// server port 
  port: 8080,

  //sqldb 
  db_host:'localhost',
  db_port:'3306',
  db_username:'root',
  db_password:'',
  db_name:'test',
  db_pool_num:5,

  //redis
  redis_host:'127.0.0.1',
  redis_port:6379,
  redis_password:"",
  redis_db:0,
  redis_family:4,

  //cache
  cache_prefix:'temp_prod_'
 
};

module.exports= {common}