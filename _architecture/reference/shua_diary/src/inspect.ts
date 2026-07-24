import { DiaryRepository } from './diary/diary_repository';

const repo = new DiaryRepository();
console.log("--- DIARY ENTRIES ---");
console.log(repo.getEntriesList('default'));

console.log("--- DIARY BLOCKS ---");
// Get blocks for the entry mentioned in logs
const entryId = '70b0d59e-22ae-4a33-9e5a-6e788d9ed93a';
console.log(repo.getEntryBlocks(entryId));




