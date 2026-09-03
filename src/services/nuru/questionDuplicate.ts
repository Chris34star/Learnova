export function normalizeQuestion(value:string){return value.toLocaleLowerCase().replace(/[“”‘’]/g,"'").replace(/[^\p{L}\p{N}\s'=+\-*/.]/gu,' ').replace(/\s+/g,' ').trim()}

// Stable non-cryptographic fingerprint for browser previews. The database uses SHA-256.
export function questionFingerprint(value:string){let hash=2166136261;for(const char of normalizeQuestion(value)){hash^=char.charCodeAt(0);hash=Math.imul(hash,16777619)}return (hash>>>0).toString(16).padStart(8,'0')}

export function flagDuplicates<T extends {question:string;id:string}>(incoming:T[],existing:T[]){const seen=new Map(existing.map(q=>[normalizeQuestion(q.question),q.id]));return incoming.map(q=>{const normalized=normalizeQuestion(q.question);const duplicateOf=seen.get(normalized);if(!duplicateOf)seen.set(normalized,q.id);return {...q,duplicateOf}})}
