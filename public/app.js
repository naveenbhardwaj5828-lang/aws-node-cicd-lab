const button = document.querySelector('#healthButton');
const result = document.querySelector('#healthResult');

button.addEventListener('click', async () => {
  result.textContent = 'Checking…';
  try {
    const response = await fetch('/health');
    const data = await response.json();
    result.textContent = response.ok ? `✓ Service is ${data.status}` : 'Service check failed';
  } catch {
    result.textContent = 'Unable to reach the service';
  }
});
