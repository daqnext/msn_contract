const koa =require('koa');
const router =require( 'koa-router');
const path =require( 'path');
const {args} =require(  '../configs/args.js');
const log4js =require( 'log4js');
const axios =require( "axios");
const randomstring =require( "randomstring");
const { Module } = require('module');


//////////////////////////////////////////
let ROOTDIR=path.resolve();

//////////global koa//////////////
let koaApp = new koa();
let koaRouter = new router();


///////////global log4js//////////////
log4js.configure({
    appenders: {
        file: {
            type: 'file',
            filename: ROOTDIR+"/log/"+args.logfilename, 
            maxLogSize: 500000,
            backups: 5,
            replaceConsole: true,
        },
        console: {
            type: 'console',
            replaceConsole: true,
        },
    },
    categories: {
        default: { appenders: args.logtypes,level: args.loglevel },
    },

    pm2: true,
    pm2InstanceVar: 'INSTANCE_ID',
    disableClustering: true
});

let logger=log4js.getLogger('default');

module.exports={args,ROOTDIR,koaApp,koaRouter,logger,axios,randomstring};

