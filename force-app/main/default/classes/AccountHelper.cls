public class AccountHelper {
    public static void renameAccount(Id accountId, String newName) {
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId];
        acc.Name = newName;
        update acc;
    }
}