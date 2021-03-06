#! /bin/sh

. ${testdir}/_init_log_setup.sh
. ${libdir}/_cert_functions.sh

privkey=/tmp/keys/test-privkey
dirpriv=$(dirname $privkey)
pubkey=/tmp/keys/test-pubkey
dirpub=$(dirname $pubkey)

echo "Variables for cert-test:"
echo "privkey: $privkey"
echo "dirpriv: $dirpriv"
echo "pubkey: $pubkey"
echo "dirpub: $dirpub"

tearDown(){
	if [ -d $acme_challenge_dir ]; then rmdir -p $acme_challenge_dir; fi
	if [ -f $privkey ]; then rm $privkey; fi
	if [ -f $pubkey ]; then rm $pubkey; fi
}

testAcmeChallengeDir(){
	assertFalse " [ -d $acme_challenge_dir ] "
	create_acme_challenge_dir
	assertTrue " [ -d $acme_challenge_dir ] "
	# TODO: test ownership
}

testCertificateExists(){
	mkdir -p $dirpriv $dirpub
	touch $privkey $pubkey
	certificate_exists $privkey $pubkey
	assertEquals 0 $?
}

testCertificateExistsOnlyPrivkey(){
	mkdir -p $dirpriv
	touch $privkey
	certificate_exists $privkey $pubkey
	assertEquals 1 $?
}

testCertificateExistsOnlyPubkey(){
	mkdir -p $dirpub
	touch $pubkey
	certificate_exists $privkey $pubkey
	assertEquals 2 $?
}

testCertificateExistsEmpty(){
	certificate_exists $privkey $pubkey
	assertEquals 255 $?
}

testCertificateCreateSelfsigned(){
	certificate_create $privkey $pubkey selfsigned
	assertTrue " [ -f $privkey ] "
	assertTrue " [ -f $pubkey ] "
	# TODO: test different aspects of certificate
}

testCertificateCreateSelfsignedRefused(){
	mkdir -p $dirpriv
	touch $privkey
	certificate_create $privkey $pubkey selfsigned
	assertEquals 1 $?
	assertTrue " [ -f $privkey ] "
	assertFalse " [ -f $pubkey ] "
}

# TODO: Test certbot without requiring letsencrypt server

testCertificateCreateLetsencryptRefused(){
	# Test with both variables missing
	certificate_create $privkey $pubkey certbot
	assertEquals 1 $?
	expected="[ERROR] certificate_create(): variable certbot_domain or certbot_mail are not set"
	actual=$(tail -n1 $testStdErr)
	assertEquals "$expected" "$actual"
	# Test with one variable missing
	certificate_create $privkey $pubkey certbot "my.example.org"
	assertEquals 1 $?
	actual=$(tail -n1 $testStdErr)
	assertEquals "$expected" "$actual"
}

testCertificateCreateNonsenseMethod(){
	certificate_create $privkey $pubkey nonsense
	assertEquals 1 $?
}

testCertificateUpdateSelfSigned(){
	mkdir -p $dirpriv $dirpub
	touch $privkey $pubkey
	certificate_renew $privkey $pubkey selfsigned
	assertEquals 0 $?
	assertTrue " [ -f $privkey ] "
	assertTrue " [ -f $pubkey ] "
	# TODO: test filesize > 0
}

testCertificateUpdateSelfSignedRefused(){
	certificate_renew $privkey $pubkey selfsigned
	assertEquals 1 $?
}

# TODO: Test certbot renew without requiring letsencrypt server

testCertificateUpdateNonsenseMethod(){
	touch $privkey $pubkey
	certificate_renew $privkey $pubkey nonsense
	assertEquals 1 $?
}

. ${extlibdir}/shunit2/shunit2
