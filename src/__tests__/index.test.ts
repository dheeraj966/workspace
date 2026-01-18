import { main } from '../index';

describe('Antigravity', () => {
  it('should be defined', () => {
    expect(main).toBeDefined();
  });

  it('should execute without errors', () => {
    expect(() => main()).not.toThrow();
  });
});
