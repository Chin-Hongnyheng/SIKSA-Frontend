// A dummy service worker to satisfy Firebase Messaging's requirement on Web.
// If you want to receive background notifications on Web, you must configure this file
// with your Firebase config. For now, this empty file prevents the MIME type error.
self.addEventListener('fetch', function(event) {
});
