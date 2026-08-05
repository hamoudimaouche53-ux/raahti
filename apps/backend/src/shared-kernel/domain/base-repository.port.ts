/**
 * Base repository interface conventions shared by every module's domain/ repository
 * ports (repository-structure.md §3). Modules declare their own narrower ports
 * (e.g. UserRepository) that extend or compose this shape — this is not itself
 * injected anywhere.
 */
export interface Repository<TEntity, TId> {
  findById(id: TId): Promise<TEntity | null>;
  save(entity: TEntity): Promise<void>;
}
