export async function fetchNui(eventName, data) {
  const resp = await fetch(`https://sleepless_interact/${eventName}`, {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  });

  return await resp.json();
}
