import fs from 'node:fs/promises';
const [,,path='private-import/data.json']=process.argv;
const url=process.env.SUPABASE_URL, key=process.env.SUPABASE_SERVICE_ROLE_KEY;
if(!url||!key) throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
const data=JSON.parse(await fs.readFile(path,'utf8'));
const headers={'apikey':key,'Authorization':`Bearer ${key}`,'Content-Type':'application/json','Prefer':'resolution=merge-duplicates,return=representation'};
async function upsert(table,rows,onConflict){let saved=[];for(let i=0;i<rows.length;i+=100){const r=await fetch(`${url}/rest/v1/${table}?on_conflict=${onConflict}`,{method:'POST',headers,body:JSON.stringify(rows.slice(i,i+100))});if(!r.ok)throw new Error(`${table}: ${r.status} ${await r.text()}`);saved.push(...await r.json())}return saved}
const members=await upsert('team_members',data.team_members,'source_row');
const colleges=await upsert('colleges',data.colleges,'source_row');
const memberIds=new Map(members.map(x=>[x.source_row,x.id]));const collegeIds=new Map(colleges.map(x=>[x.college_name.toLowerCase(),x.id]));
const assignments=data.assignments.map(a=>{const exact=collegeIds.get(String(a.college_label).toLowerCase());return{member_id:memberIds.get(a.member_source_row),college_id:exact||null,assignment_date:a.assignment_date,status:a.status,notes:exact?null:a.college_label}}).filter(x=>x.member_id);
await upsert('assignments',assignments,'id');console.log(`Imported ${members.length} team members, ${colleges.length} colleges and ${assignments.length} roster entries.`);
