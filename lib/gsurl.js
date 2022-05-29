const gsurls = module.exports = {
    fromUrl: function(url) {
        if (url.startsWith("https://storage.cloud.google.com/")) {
            let parts = url.substring(33).split("/");
            if (parts.length == 2) {
                return {
                    Bucket: parts[0],
                    Key: parts[1]
                };
            }
        }
        return {};
    },
    valid: function(url) {
        const params = fromUrl(url);
        return params.Bucket && params.Key;
    }
};