



function patch()
{
    
    # 과거 패키지, 유지하고 향후 별도 스케쥴러에서 삭제하도록 변경
    #rm -rf aivax-install.v1.0.1.$(date +%Y%m%d).tar.gz

    # package_date=$(date +%Y%m%d%H%M)
    package_date=$(date +%Y%m%d)
    # today=$(date +%Y%m%d)

    aivax_ver=v1.0.0.0

    aivax_package_root="/data/data-root/aivax-install-root"

    cd ${aivax_package_root}


    #임시 방편, 우선 현재 파일의 hash를 구분할수 있도록 설정한다.
    #aivax의 패치 형상을 기준으로 hash를 만든다.

    #install.sh가 변경시에도 hash를 만들도록 임시 추가, 향후 git의 hash로 처리되어야 한다.
    cp -rfv aivax-install/install.sh aivax-install/aivax-patch/install-temp

    hash=$(tar -cf - aivax-install/aivax-patch/ | sha256sum | awk '{print $1}' | cut -c1-6)

    #패키지를 만들기전, 임시파일 삭제
    rm -rf aivax-install/aivax-patch/install-temp

    aivax_package_file=aivax-install.${aivax_ver}.$package_date.${hash}

    cp -rfv aivax-install ${aivax_package_file}

    tar -czf ${aivax_package_file}.tar.gz ${aivax_package_file}

    # #마지막. 날짜뒤에 hash 추가 => TODO: hash 전략 필요, hash로 git정보를 알수 있어야 한다.
    # #version 파일을 생성 => aivax, pipeline, sslproxy 3개 조합의 파일
    # file="aivax-install.${aivax_ver}.$today.tar.gz"

    # new_file="aivax-install.${aivax_ver}.$today.${hash}.tar.gz"

    # # 파일 이름 변경
    # mv "$file" "$new_file"

    #마지막, 임시파일 삭제
    rm -rf ${aivax_package_file}
}