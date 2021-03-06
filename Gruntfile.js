module.exports = function (grunt) {
    grunt.initConfig({
        shell: {
            test: {
                options: {
                    stdout: true
                },
                command: 'powershell scripts\\lib\\test.ps1'
            },
            push: {
                command: "powershell scripts\\lib\\push.ps1 -newversion"
            }          
        }
    });

    grunt.loadNpmTasks('grunt-shell');
    
    grunt.registerTask('test', ['shell:test']);
    grunt.registerTask('push', ['shell:test', 'shell:push']);
}