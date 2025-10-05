export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  url: env('URL', 'https://admin.insantaqwa.org/karya-smp'),
  app: {
    keys: env.array('APP_KEYS'),
  },
});
