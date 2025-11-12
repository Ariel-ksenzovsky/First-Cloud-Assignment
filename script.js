function incrementCounter() {
  let count = localStorage.getItem('visits');
  count = count ? parseInt(count) + 1 : 1;
  localStorage.setItem('visits', count);
  document.getElementById('counter').textContent = count;
}

// Load counter value when page loads
window.onload = function() {
  const count = localStorage.getItem('visits') || 0;
  document.getElementById('counter').textContent = count;
};
