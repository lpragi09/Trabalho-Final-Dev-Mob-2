// Testa firestore.rules no Firebase Emulator (projeto "demo-", sem produção).
// Uso: cd rules_test && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let env;
const recipe = (uid, extra = {}) => ({
  ownerId: uid,
  mealId: '52772',
  title: 'Teriyaki Chicken Casserole',
  category: 'Chicken',
  thumbnailUrl: '',
  note: '',
  rating: 4,
  ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-minhas-receitas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());

const dbOf = (uid) => env.authenticatedContext(uid).firestore();

test('PERMITIDA: usuário A cria, lê, atualiza e remove o próprio documento', async () => {
  const ref = doc(dbOf('userA'), 'users/userA/saved_recipes/r1');
  await assertSucceeds(setDoc(ref, recipe('userA')));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { rating: 5, note: 'Menos açúcar' }));
  await assertSucceeds(deleteDoc(ref));
});

test('NEGADA: usuário B tenta ler e apagar documento do usuário A', async () => {
  await assertSucceeds(setDoc(doc(dbOf('userA'), 'users/userA/saved_recipes/r1'), recipe('userA')));
  const asB = doc(dbOf('userB'), 'users/userA/saved_recipes/r1');
  await assertFails(getDoc(asB));
  await assertFails(deleteDoc(asB));
});

test('NEGADA: usuário B tenta criar documento na pasta do usuário A', async () => {
  const ref = doc(dbOf('userB'), 'users/userA/saved_recipes/intruso');
  await assertFails(setDoc(ref, recipe('userA')));
});

test('NEGADA: visitante sem login não lê nada', async () => {
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, 'users/userA/saved_recipes/r1')));
});

test('NEGADA: dados inválidos (nota 9, ownerId trocado)', async () => {
  const db = dbOf('userA');
  await assertFails(setDoc(doc(db, 'users/userA/saved_recipes/r2'), recipe('userA', { rating: 9 })));
  await assertFails(setDoc(doc(db, 'users/userA/saved_recipes/r3'), recipe('userB')));
  await assertSucceeds(setDoc(doc(db, 'users/userA/saved_recipes/r4'), recipe('userA')));
  await assertFails(updateDoc(doc(db, 'users/userA/saved_recipes/r4'), { ownerId: 'userB' }));
});
