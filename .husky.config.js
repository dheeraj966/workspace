// Husky configuration for git hooks
// After installing: npx husky install

export default {
  hooks: {
    'pre-commit': 'lint-staged',
    'pre-push': 'npm run type-check && npm run test'
  }
};
