// The app has no password login — a user simply picks their name once, and we
// remember it. That profile id is what predictions are saved under.
const ID = 'eg.userId';
const NAME = 'eg.userName';

export function getUserId(): string | null {
  return localStorage.getItem(ID);
}

export function getUserName(): string | null {
  return localStorage.getItem(NAME);
}

export function setIdentity(id: string, name: string) {
  localStorage.setItem(ID, id);
  localStorage.setItem(NAME, name);
}

export function clearIdentity() {
  localStorage.removeItem(ID);
  localStorage.removeItem(NAME);
}
