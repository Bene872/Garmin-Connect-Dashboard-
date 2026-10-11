import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,sep,extname} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=resolve(fileURLToPath(new URL('../dist/',import.meta.url)));
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.ico':'image/x-icon'};

function json(res,status,data){res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(data));}
export function createApp(){return createServer(async(req,res)=>{
 res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','no-referrer');res.setHeader('X-Frame-Options','DENY');
 res.setHeader('Permissions-Policy','camera=(), microphone=(), geolocation=()');
 res.setHeader('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'");
 try{
  const url=new URL(req.url,'http://localhost');
  if(req.method!=='GET'&&req.method!=='HEAD'){
   res.setHeader('Allow','GET, HEAD');return json(res,405,{error:'METHOD_NOT_ALLOWED'});
  }
  if(url.pathname==='/api/health')return json(res,200,{status:'ok',service:'pulse-backend'});
  if(url.pathname==='/api/health/status')return json(res,200,{provider:'apple-health',state:'native_app_required',connected:false,message:'HealthKit wird lokal in der nativen iPhone-App gelesen. Dieser Server hat keinen Health-Zugriff.'});
  if(url.pathname==='/api/dashboard')return json(res,409,{error:'NATIVE_HEALTH_REQUIRED',message:'Health-Daten werden ausschließlich lokal in der iPhone-App gelesen.'});
  if(url.pathname.startsWith('/api/'))return json(res,404,{error:'NOT_FOUND'});
  const path=resolve(root,'.'+decodeURIComponent(url.pathname));
  if(path!==root&&!path.startsWith(root+sep))return json(res,404,{error:'NOT_FOUND'});
  let target=path===root?resolve(root,'index.html'):path;
  try{if(!(await stat(target)).isFile())return json(res,404,{error:'NOT_FOUND'});}catch{return json(res,404,{error:'NOT_FOUND'});}
  const body=await readFile(target);res.writeHead(200,{'Content-Type':types[extname(target)]||'application/octet-stream','Cache-Control':extname(target)==='.html'?'no-cache':'public, max-age=3600'});res.end(req.method==='HEAD'?undefined:body);
 }catch{json(res,400,{error:'BAD_REQUEST'});}
});}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const port=Number(process.env.PORT||3000);createApp().listen(port,process.env.HOST||'127.0.0.1',()=>console.log(`Pulse backend listening on port ${port}. HealthKit access is local to the native iPhone app.`));
}
