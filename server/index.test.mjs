import test from 'node:test';import assert from 'node:assert/strict';import {once} from 'node:events';import {createApp} from './index.mjs';
test('Backend serves the app and fails closed for server-side HealthKit access',async()=>{
 const server=createApp();server.listen(0,'127.0.0.1');await once(server,'listening');const base=`http://127.0.0.1:${server.address().port}`;
 try{
  const health=await fetch(base+'/api/health');assert.equal(health.status,200);assert.equal((await health.json()).status,'ok');
  const status=await (await fetch(base+'/api/health/status')).json();assert.equal(status.connected,false);assert.equal(status.state,'native_app_required');
  const dashboard=await fetch(base+'/api/dashboard');assert.equal(dashboard.status,409);assert.equal((await dashboard.json()).error,'NATIVE_HEALTH_REQUIRED');
  const unknown=await fetch(base+'/api/nope');assert.equal(unknown.status,404);assert.match(unknown.headers.get('content-type'),/application\/json/);
  const app=await fetch(base+'/');assert.equal(app.status,200);assert.match(await app.text(),/Pulse|pulse/);assert.match(app.headers.get('content-security-policy'),/frame-ancestors 'none'/);
  const denied=await fetch(base+'/%2e%2e%2fpackage.json');assert.equal(denied.status,404);
  const post=await fetch(base+'/',{method:'POST'});assert.equal(post.status,405);
 }finally{server.closeAllConnections();await new Promise(r=>server.close(r));}
});
