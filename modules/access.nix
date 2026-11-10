{ ... }:
{
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCb9qGUB7qYNPMQWAzgAUkJJwLvzKwjkZ9tKUiZKusuPOCupZrGjeofI68h3gFUNNiDzWOQcOZQvVu2Zyz7XaJSBR7SW1Dkdwt7jMP5a4Tdmn+4dsnbDKcyDl4XPx73KoFbRAOl2aBHCpHJX8uevbcaXl08a3JYLo3VlIU0LBZzUu1J6Kkz4deJGDq64uFTNI72AdeA8DL890OEszBo0DxYnXN0qi/MQgGiho55OQhHgNDuB4QIh/ON6JvH982oPbUIsAr16QodH1DVTsHdJeWuBXoMW3XRNp8wNrx4Zc4kMnEzhQUx0tHcvf66tlEhy+RmEnG0tItOp1YDdt/WWac47G5N43MUJcysj3XFSfiywpRuPMat85VwF+AdEZgXzYitpSORgypDIM0EbnBwY9PBU1EslcApSYcMkRMOcuHq6Hrv6q514NBpie3JMANDxEIjKRR5HEvebDtQcQxtblTfvWqr8iEpr9Lrav/CWGt7Buv6Dtyp2lEljY58i3YplZk/MRuBPobz9uTf2KjkvwJcbzjmpC+4lg0Gr8jmkpdxIeu8jcuSQfrEmsdHvQgS93nuvGZl8ztDccYhZJO+GLy+UzDXshmEfEBrLi+WyT9gkMjhNV79ql9GKAV2SKJaUQHlDHHVVhijbdoAj0i6hXn+NND8mKLFq+zYS3ouTem0jw== me@archlinux"
    ];
  };

  # Deliberate convenience choice: admin (and agents it runs) can become root.
  security.sudo.wheelNeedsPassword = false;
}
