import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
const dist=resolve('dist');
let html=readFileSync(resolve(dist,'index.html'),'utf8');
html=html.replace(/<script\b[^>]*src="([^"]+)"[^>]*><\/script>/g,(_,src)=>'<script type="module">'+readFileSync(resolve(dist,src.replace(/^\//,'')),'utf8').replaceAll('</script','<\\/script')+'</script>');
html=html.replace(/<link\b[^>]*href="([^"]+\.css)"[^>]*>/g,(_,src)=>'<style>'+readFileSync(resolve(dist,src.replace(/^\//,'')),'utf8')+'</style>');
mkdirSync('docs',{recursive:true});writeFileSync('docs/index.html',html);writeFileSync('docs/.nojekyll','');
console.log('GitHub Pages demo exported to docs/index.html');
