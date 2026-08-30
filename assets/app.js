
const config=window.BEAUTYLINK_CONFIG||{mode:'demo'};
const money=n=>new Intl.NumberFormat('fr-FR').format(Number(n||0))+' FCFA';
const safeText=value=>String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const products=[
{id:1,name:'Sérum Éclat Niacinamide',cat:'visage',emoji:'🧪',price:18500,rating:4.7,stock:42},
{id:2,name:'Crème Baobab SPF30',cat:'visage',emoji:'🧴',price:14900,rating:4.5,stock:15},
{id:3,name:'Nettoyant Doux Sans Savon',cat:'visage',emoji:'🫧',price:8500,rating:4.8,stock:96},
{id:4,name:'Eau de Parfum Dakar Nuit',cat:'parfums',emoji:'🌙',price:39000,rating:4.9,stock:9},
{id:5,name:'Huile Barbe & Visage',cat:'homme',emoji:'🧔🏾',price:12000,rating:4.6,stock:31},
{id:6,name:'Roller visage quartz',cat:'accessoires',emoji:'💎',price:6500,rating:4.4,stock:54},
{id:7,name:'Brume Fleur de Bissap',cat:'parfums',emoji:'🌺',price:22500,rating:4.7,stock:22},
{id:8,name:'Trousse routine voyage',cat:'accessoires',emoji:'👜',price:9900,rating:4.5,stock:18}
];
const experts=[
{name:'Dr Aïssatou Diagne',title:'Dermatologue',badge:'Médecin vérifié',emoji:'👩🏾‍⚕️',rating:'4,9',reviews:184,price:25000,bio:'Hyperpigmentation, acné et suivi des peaux noires et métissées.'},
{name:'Fatou Ndiaye',title:'Esthéticienne & Skincare Coach',badge:'Professionnelle vérifiée',emoji:'👩🏾',rating:'4,8',reviews:233,price:12000,bio:'Routines, soins visage et accompagnement non médical.'},
{name:'Moussa Ba',title:'Barbier & Grooming Expert',badge:'Professionnel vérifié',emoji:'🧔🏾',rating:'4,7',reviews:96,price:8000,bio:'Barbe, cuir chevelu et routines de grooming homme.'}
];
const posts=[
{author:'Dr Aïssatou Diagne',badge:'Médecin vérifié',kind:'Contenu médical éducatif',body:'L’éclaircissement volontaire de la peau peut entraîner des complications. Privilégiez une information médicale fiable et une photoprotection adaptée.',emoji:'🛡️',likes:892,comments:74},
{author:'Fatou Skin Coach',badge:'Professionnelle vérifiée',kind:'Conseil beauté',body:'Ordre simple : nettoyant, sérum, hydratant, protection solaire. Introduisez un actif à la fois et observez la tolérance.',emoji:'✨',likes:531,comments:42},
{author:'Teranga Skin',badge:'Marque officielle',kind:'Contenu sponsorisé',body:'Le coffret routine peau grasse est de retour en stock. Cette publication commerciale est clairement identifiée comme sponsorisée.',emoji:'🧴',likes:216,comments:18}
];
const defaultCart=[
{id:1,qty:1,selected:true,status:'À acheter'},
{id:2,qty:1,selected:true,status:'Recommandé'},
{id:3,qty:2,selected:false,status:'Commencé'}
];
let cart=(()=>{try{return JSON.parse(localStorage.getItem('beautylink-care-cart'))||defaultCart}catch{return defaultCart}})();
const saveCart=()=>localStorage.setItem('beautylink-care-cart',JSON.stringify(cart));
function showView(id){
 document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));
 const page=document.getElementById(id); if(page) page.classList.add('active');
 document.querySelectorAll('.nav-item').forEach(b=>b.classList.toggle('active',b.dataset.view===id));
 window.scrollTo({top:0,behavior:'smooth'});
 location.hash=id;
}
document.addEventListener('click',e=>{const b=e.target.closest('[data-view]');if(b){e.preventDefault();showView(b.dataset.view)}});
function toast(msg){const el=document.getElementById('toast');el.textContent=msg;el.classList.add('show');clearTimeout(window.__toast);window.__toast=setTimeout(()=>el.classList.remove('show'),2500)}
function renderPosts(){
 document.getElementById('postList').innerHTML=posts.map((p,i)=>`<article class="card post"><div class="post-head"><div class="post-avatar">${p.author.split(' ').map(x=>x[0]).slice(0,2).join('')}</div><div><strong>${p.author}</strong><div class="small muted">${p.badge} · ${p.kind}</div></div></div><p class="post-body">${p.body}</p><div class="post-media">${p.emoji}</div><div class="post-actions"><button onclick="likePost(${i},this)">♡ ${p.likes}</button><button onclick="toast('Commentaires ouverts')">💬 ${p.comments}</button><button onclick="this.textContent=this.textContent.includes('Enregistré')?'🔖 Enregistrer':'✓ Enregistré'">🔖 Enregistrer</button><button onclick="toast('Publication signalée à la modération')">⚑ Signaler</button></div></article>`).join('');
}
function publishPost(){const t=document.getElementById('composer');if(!t.value.trim())return toast('Écrivez un contenu avant de publier');posts.unshift({author:'Mariama Sow',badge:'Consommatrice',kind:'Journal de routine',body:safeText(t.value.trim()),emoji:'📷',likes:0,comments:0});t.value='';renderPosts();toast('Publication ajoutée au fil')}
function likePost(i,b){posts[i].likes++;b.textContent='♥ '+posts[i].likes;b.style.color='#c64b53'}
function renderExperts(){document.getElementById('expertGrid').innerHTML=experts.map((e,i)=>`<div class="card expert-card"><div class="expert-cover">${e.emoji}</div><div class="row between"><span class="badge green">${e.badge}</span><span class="rating">★ ${e.rating} (${e.reviews})</span></div><div><h3>${e.name}</h3><strong>${e.title}</strong><p class="muted">${e.bio}</p></div><div class="row between"><strong>${money(e.price)}</strong><button class="btn primary" onclick="bookExpert(${i})">Réserver</button></div><button class="btn" onclick="showView('messages');toast('Conversation sécurisée ouverte')">Envoyer un message</button></div>`).join('')}
function renderProducts(cat='all'){const list=cat==='all'?products:products.filter(p=>p.cat===cat);document.getElementById('productGrid').innerHTML=list.map(p=>`<div class="card product"><div class="product-art">${p.emoji}</div><div class="product-info"><span class="badge">${p.cat}</span><h3>${p.name}</h3><div class="row between"><span class="rating">★ ${p.rating}</span><span class="muted small">${p.stock} en stock</span></div><div class="price">${money(p.price)}</div><button class="btn primary" onclick="addCart(${p.id})">Ajouter au Care Cart</button><button class="btn" onclick="toast('Produit ajouté aux favoris')">♡ Favori</button></div></div>`).join('')}
function filterProducts(cat){renderProducts(cat);toast(cat==='all'?'Tous les produits affichés':'Filtre '+cat+' appliqué')}
function addCart(id){let line=cart.find(x=>x.id===id);if(line)line.qty++;else cart.push({id,qty:1,selected:true,status:'À acheter'});saveCart();renderCart();toast('Produit ajouté au Care Cart')}
function renderCart(){
 document.getElementById('cartLines').innerHTML=cart.map((c,i)=>{let p=products.find(x=>x.id===c.id);return `<div class="cart-line"><div class="cart-art">${p.emoji}</div><div><strong>${p.name}</strong><div class="muted small">${c.status} · ${money(p.price)}</div><label class="small"><input type="checkbox" ${c.selected?'checked':''} onchange="cart[${i}].selected=this.checked;renderCart()"> Valider maintenant</label></div><div class="qty"><button onclick="changeQty(${i},-1)">−</button><strong>${c.qty}</strong><button onclick="changeQty(${i},1)">+</button></div><button class="icon-btn" onclick="removeCart(${i})">✕</button></div>`}).join('');
 const subtotal=cart.filter(c=>c.selected).reduce((s,c)=>s+products.find(p=>p.id===c.id).price*c.qty,0);
 document.getElementById('subtotal').textContent=money(subtotal);document.getElementById('grandtotal').textContent=money(subtotal+(subtotal?2000:0));document.getElementById('cartCount').textContent=cart.length;
}
function changeQty(i,d){cart[i].qty=Math.max(1,cart[i].qty+d);saveCart();renderCart()}
function removeCart(i){cart.splice(i,1);saveCart();renderCart();toast('Produit retiré')}
function selectAllCart(){cart.forEach(c=>c.selected=true);saveCart();renderCart();toast('Tous les produits sont sélectionnés')}
function shareCart(){toast('Lien privé de Care Cart créé pour le professionnel')}
function renderRoutine(){
 const morning=['Nettoyant doux','Sérum niacinamide','Crème SPF30'];const evening=['Nettoyant doux','Crème hydratante','Journal & feedback'];
 const r=(x,i)=>`<div class="reminder"><span>${i+1}</span><div><strong>${x}</strong><div class="muted small">${i===0?'Nettoyer délicatement':'Suivre les instructions enregistrées'}</div></div><button class="btn soft" onclick="completeTask(this)">Valider</button></div>`;
 document.getElementById('morningRoutine').innerHTML=morning.map(r).join('');document.getElementById('eveningRoutine').innerHTML=evening.map(r).join('');
}
function renderReminders(){
 const items=[['☀️','Routine du matin','Chaque jour à 07:00',true],['💬','Feedback sérum J+14','Dans 7 jours · WhatsApp',true],['📦','Produit bientôt terminé','Estimation dans 12 jours',true],['🛍️','Panier abandonné','Après 6 heures',false],['⚕','Rendez-vous dermatologue','Samedi à 10:30',true]];
 document.getElementById('reminderList').innerHTML='<h3>Rappels actifs</h3>'+items.map(x=>`<div class="reminder"><span>${x[0]}</span><div><strong>${x[1]}</strong><div class="muted small">${x[2]}</div></div><button class="switch ${x[3]?'on':''}" onclick="toggleSwitch(this)"></button></div>`).join('');
}
function completeTask(b){b.textContent='✓ Fait';b.classList.remove('soft');b.classList.add('primary');toast('Étape enregistrée')}
function toggleSwitch(b){b.classList.toggle('on');toast(b.classList.contains('on')?'Préférence activée':'Préférence désactivée')}
function openAI(){document.getElementById('aiModal').classList.add('open')}
function closeModal(id){document.getElementById(id).classList.remove('open')}
function closeOnBackdrop(e,id){if(e.target.id===id)closeModal(id)}
function askAI(){const input=document.getElementById('aiInput');if(!input.value.trim())return;const log=document.getElementById('aiLog');log.innerHTML+=`<div class="bubble me">${input.value.replace(/</g,'&lt;')}</div>`;let answer='Je peux vous proposer une routine cosmétique simple à partir de votre profil et des produits disponibles. Introduisez un produit à la fois et arrêtez en cas de réaction.';if(/douleur|saigne|grave|urgence|gonfl/i.test(input.value))answer='Ces signes nécessitent une évaluation humaine. Je ne peux pas poser de diagnostic. Contactez rapidement un professionnel de santé ou un service d’urgence approprié.';log.innerHTML+=`<div class="bubble">${answer}</div>`;input.value='';log.lastElementChild.scrollIntoView({behavior:'smooth'})}
function openCheckout(){if(!cart.some(c=>c.selected))return toast('Sélectionnez au moins un produit');document.getElementById('checkoutModal').classList.add('open')}
function paySandbox(){closeModal('checkoutModal');cart.filter(c=>c.selected).forEach(c=>c.status='Payé (démo)');saveCart();renderCart();toast('Paiement sandbox validé — aucun débit réel')}
function bookExpert(i){document.getElementById('bookingTitle').textContent='Rendez-vous avec '+experts[i].name;document.getElementById('bookingModal').classList.add('open')}
function confirmBooking(){closeModal('bookingModal');toast('Rendez-vous de démonstration confirmé')}
function sendMessage(){const i=document.getElementById('chatInput');if(!i.value.trim())return;document.getElementById('chatLog').innerHTML+=`<div class="bubble me">${i.value.replace(/</g,'&lt;')}</div>`;i.value='';toast('Message envoyé en mode démonstration')}
function toggleControl(b){b.style.background=b.style.background?'':'rgba(198,75,83,.85)';toast('Contrôle audio/vidéo simulé')}
function endCall(){showView('messages');toast('Appel de démonstration terminé — résumé créé')}
function orderTimeline(){toast('Commande #BL-12548 : préparée → expédiée → en livraison')}
function approve(b){b.textContent='✓ Vérifié';b.classList.remove('primary');b.classList.add('soft');toast('Décision de vérification enregistrée')}
function moderate(b){b.textContent='✓ Traité';b.classList.remove('coral');b.classList.add('soft');toast('Action de modération journalisée')}
document.getElementById('roleSwitch').addEventListener('change',e=>{const map={consumer:'dashboard',professional:'professional',doctor:'professional',seller:'seller',admin:'admin'};showView(map[e.target.value]);toast('Rôle de démonstration : '+e.target.options[e.target.selectedIndex].text)})
document.getElementById('globalSearch').addEventListener('keydown',e=>{if(e.key==='Enter'){showView('shop');toast('Résultats pour « '+e.target.value+' »')}})
async function hydrateFromSupabase(){
 const banner=document.getElementById('connectionBanner');
 if(!config.supabaseUrl||!config.supabaseAnonKey||config.mode!=='connected'){
  banner.textContent='Mode démonstration sécurisé — aucune donnée médicale réelle et aucun paiement réel.';
  banner.className='connection-banner visible';
  return;
 }
 try{
  const base=config.supabaseUrl.replace(/\/$/,'')+'/rest/v1';
  const headers={apikey:config.supabaseAnonKey,Authorization:'Bearer '+config.supabaseAnonKey};
  const response=await fetch(base+'/products?select=id,name,category,price_xof,is_active&is_active=eq.true&limit=50',{headers});
  if(!response.ok)throw new Error('HTTP '+response.status);
  const rows=await response.json();
  if(Array.isArray(rows)&&rows.length){
   const emojis={face:'🧴',visage:'🧴',body:'🧼',corps:'🧼',hair:'💇🏾‍♀️',cheveux:'💇🏾‍♀️',beard:'🧔🏾',barbe:'🧔🏾',fragrance:'🌸',parfums:'🌸',accessories:'💎',accessoires:'💎'};
   products.splice(0,products.length,...rows.map(row=>({id:Number(row.id),name:row.name,cat:row.category||'visage',emoji:emojis[row.category]||'🧴',price:Number(row.price_xof||0),rating:4.6,stock:99})));
   cart=cart.filter(item=>products.some(product=>product.id===item.id));
   renderProducts();renderCart();
  }
  banner.textContent='Connecté à Supabase — les produits actifs proviennent de la base distante.';
  banner.className='connection-banner visible';
 }catch(error){
  console.warn('Supabase indisponible, retour au mode démo',error);
  banner.textContent='Supabase indisponible : affichage des données de démonstration locales.';
  banner.className='connection-banner visible';
 }
}

renderPosts();renderExperts();renderProducts();renderCart();renderRoutine();renderReminders();
hydrateFromSupabase();
if(location.hash && document.getElementById(location.hash.slice(1)))showView(location.hash.slice(1));
if('serviceWorker' in navigator && location.protocol.startsWith('http'))navigator.serviceWorker.register('./sw.js').catch(()=>{});
